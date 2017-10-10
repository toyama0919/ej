require 'json'
require 'elasticsearch'
require 'hashie'
require 'parallel'
require 'logger'

class HashWrapper < ::Hashie::Mash
  disable_warnings if respond_to?(:disable_warnings)
end

module Ej
  class Core
    def initialize(values)
      @logger =  values.logger
      @index = values.index
      @client = values.client
    end

    def search(type, query, size, from, meta, routing = nil, fields = nil, sort = nil)
      body = { from: from }
      body[:size] = size unless size.nil?
      if sort
        sorts = []
        sort.each do |k, v|
          sorts << { k => v }
        end
        body[:sort] = sorts
      end
      body[:query] = { query_string: { query: query } } unless query.nil?
      search_option = { index: @index, type: type, body: body }
      search_option[:routing] = routing unless routing.nil?
      search_option[:_source] = fields.nil? ? nil : fields.join(',')
      results = HashWrapper.new(@client.search(search_option))
      meta ? results : Util.get_sources(results)
    end

    def distinct(term, type, query)
      body = { size: 0, "aggs"=>{ term + "_count"=>{"cardinality"=>{"field"=>term}}}}
      body[:query] = { query_string: { query: query } } unless query.nil?
      @client.search index: @index, type: type, body: body
    end

    def dump(query, per_size)
      per = per_size || DEFAULT_PER
      num = 0
      while true
        bulk_message = []
        from = num * per
        body = { size: per, from: from }
        body[:query] = { query_string: { query: query } } unless query.nil?
        data = HashWrapper.new(@client.search index: @index, body: body)
        docs = data.hits.hits
        break if docs.empty?
        docs.each do |doc|
          source = doc.delete('_source')
          doc.delete('_score')
          bulk_message << JSON.dump({ 'index' => doc.to_h })
          bulk_message << JSON.dump(source)
        end
        num += 1
        puts bulk_message.join("\n")
      end
    end

    def facet(term, size, query)
      body = {"facets"=>
        {"terms"=>
          {"terms"=>{"field"=>term, "size"=>size, "order"=>"count", "exclude"=>[]},
           "facet_filter"=>
            {"fquery"=>
              {"query"=>
                {"filtered"=>
                  {"query"=>
                    {"bool"=>
                      {"should"=>[{"query_string"=>{"query"=>query}}]}},
                   "filter"=>{"bool"=>{"must"=>[{"match_all"=>{}}]}}}}}}}},
       "size"=>0}
      @client.search index: @index, body: body
    end

    def aggs(terms, size, query)
      body = {
        "size"=>0,
        "query"=>{
          "query_string"=>{
            "query"=>query
          }
        }
      }

      agg_terms = []
      code = %Q{['aggs']}
      terms.each_with_index do |term, i|
        term_name = "agg_#{term}"
        aggs_body = {
          term_name=>{
            "terms"=>{
              "field"=>term,
              "size"=>size,
              "order"=>{
                "_count"=>"desc"
              }
            }
          }
        }

        eval(%Q{body#{code} = aggs_body})
        code += %Q{['#{term_name}']['aggs']}
      end

      @client.search index: @index, body: body
    end

    def min(term)
      body = {
        aggs: {
          "min_#{term}" => { min: { field: term } }
        }
      }
      @client.search index: @index, body: body, size: 0
    end

    def max(term)
      body = {
        aggs: {
          "max_#{term}" => { max: { field: term } }
        }
      }
      @client.search index: @index, body: body, size: 0
    end

    def bulk(timestamp_key, type, add_timestamp, id_keys, index, data)
      template = id_keys.map { |key| '%s' }.join('_') unless id_keys.nil?
      bulk_message = []
      data.each do |record|
        if timestamp_key.nil?
          timestamp = Time.now.to_datetime.to_s
        else
          timestamp = record[timestamp_key].to_time.to_datetime.to_s
        end
        record.merge!('@timestamp' => timestamp) if add_timestamp
        meta = { index: { _index: index, _type: type } }
        meta[:index][:_id] = Util.generate_id(template, record, id_keys) unless id_keys.nil?
        bulk_message << meta
        bulk_message << record
      end
      connect_with_retry { @client.bulk body: bulk_message unless bulk_message.empty? }
    end

    def copy(source, dest, query, per_size, scroll, dest_index, slice_max)
      source_client = Elasticsearch::Client.new hosts: source
      dest_client = Elasticsearch::Client.new hosts: dest

      parallel_array = slice_max ? slice_max.times.to_a : [0]
      Parallel.map(parallel_array, :in_processes=>parallel_array.size) do |slice_id|
        scroll_option = get_scroll_option(@index, query, per_size, scroll, slice_id, slice_max)
        r = connect_with_retry { source_client.search(scroll_option) }
        total = r['hits']['total']
        i = 0
        i += bulk_results(r, dest_client, i, total, dest_index, slice_id)

        while r = connect_with_retry { source_client.scroll(scroll_id: r['_scroll_id'], scroll: scroll) } and
          (not r['hits']['hits'].empty?) do
          i += bulk_results(r, dest_client, i, total, dest_index, slice_id)
        end
      end
    end

    private

    def bulk_results(results, dest_client, before_size, total, dest_index, slice_id)
      bulk_message = convert_results(results, dest_index)
      connect_with_retry do
        dest_client.bulk body: bulk_message unless bulk_message.empty?
        to_size = before_size + (bulk_message.size/2)
        @logger.info "slice_id[#{slice_id}] copy complete (#{before_size}-#{to_size})/#{total}"
      end
      return (bulk_message.size/2)
    end

    def get_scroll_option(index, query, size, scroll, slice_id, slice_max)
      body = {}
      body[:query] = { query_string: { query: query } } unless query.nil?
      body[:slice] = { id: slice_id, max: slice_max } if slice_max
      search_option = { index: index, scroll: scroll, body: body, size: (size || DEFAULT_PER) }
      search_option
    end

    def convert_results(search_results, dest_index)
      data = HashWrapper.new(search_results)
      docs = data.hits.hits
      bulk_message = []
      docs.each do |doc|
        source = doc.delete('_source')
        doc.delete('_score')
        ['_id', '_type', '_index'].each do |meta_field|
          source.delete(meta_field)
        end
        doc._index = dest_index if dest_index 
        bulk_message << { index: doc.to_h }
        bulk_message << source
      end
      bulk_message
    end

    def connect_with_retry(retry_on_failure = 5)
      retries = 0
      begin
        yield if block_given?
      rescue => e
        if retries < retry_on_failure
          retries += 1
          @logger.warn "Could not connect to Elasticsearch, resetting connection and trying again. #{e.message}"
          sleep 10**retries
          retry
        end
        raise "Could not connect to Elasticsearch after #{retries} retries. #{e.message}"
      end
    end
  end
end
