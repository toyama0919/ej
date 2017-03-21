require 'yajl'
require 'elasticsearch'
require 'hashie'
require 'parallel'
require 'logger'

class HashWrapper < ::Hashie::Mash
  disable_warnings if respond_to?(:disable_warnings)
end

module Ej
  class Core
    DEFAULT_PER = 1000
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

    def copy(source, dest, query, per_size, proc_num, define_from = 0)
      per = per_size || DEFAULT_PER
      logger = Logger.new($stdout)
      source_client = Elasticsearch::Client.new hosts: source, index: @index
      dest_client = Elasticsearch::Client.new hosts: dest
      calculate_body = { size: 0 }
      calculate_body[:query] = { query_string: { query: query } } unless query.nil?
      calculate_data = HashWrapper.new(source_client.search index: @index, body: calculate_body)
      total = calculate_data.hits.total
      payloads = ((total/per) + 1).times.to_a
      Parallel.map(payloads, in_processes: proc_num) do |num|
        from = num * per
        if from < define_from
          logger.info("skip index (#{num} #{from}-#{from + per})/#{total}")
          next
        end
        body = { size: per, from: from }
        body[:query] = { query_string: { query: query } } unless query.nil?
        data = HashWrapper.new(source_client.search index: @index, body: body)
        docs = data.hits.hits
        bulk_message = []
        docs.each do |doc|
          source = doc.delete('_source')
          doc.delete('_score')
          ['_id', '_type', '_index'].each do |meta_field|
            source.delete(meta_field)
          end
          bulk_message << { index: doc.to_h }
          bulk_message << source
        end
        send_with_retry do
          dest_client.bulk body: bulk_message unless bulk_message.empty?
        end

        logger.info("copy complete (#{num} #{from}-#{from + docs.size})/#{total}")
      end
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
          bulk_message << Yajl::Encoder.encode({ 'index' => doc.to_h })
          bulk_message << Yajl::Encoder.encode(source)
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

    def bulk(timestamp_key, type, add_timestamp, id_keys, index)
      data = Util.parse_json(STDIN.read)
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
      bulk_message.each_slice(10000).each do |block|
        send_with_retry do
          @client.bulk body: block unless block.empty?
        end
      end
    end

    private

    def send_with_retry(retry_on_failure = 5)
      retries = 0
      begin
        yield if block_given?
      rescue => e
        if retries < retry_on_failure
          retries += 1
          @logger.warn "Could not push logs to Elasticsearch, resetting connection and trying again. #{e.message}"
          sleep 2**retries
          retry
        end
        raise "Could not push logs to Elasticsearch after #{retries} retries. #{e.message}"
      end
    end
  end
end
