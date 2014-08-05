#!/usr/bin/env ruby
# coding: utf-8
require 'yaml'
require 'yajl'
require 'elasticsearch'
require 'hashie'
require 'pp'

module Ej
  class Core
    def initialize(host, index, debug)
      @logger =  Logger.new($stderr)
      @logger.level = debug ? Logger::DEBUG : Logger::INFO
      @index = index
      @client = Elasticsearch::Client.new hosts: host, logger: @logger, index: @index
    end

    def search(type, query, size, from, source_only, routing = nil)
      body = { size: size, from: from }
      body[:query] = { query_string: { query: query } } unless query.nil?
      search_option = { index: @index, type: type, body: body }
      search_option[:routing] = routing unless routing.nil?
      results = Hashie::Mash.new(@client.search(search_option))
      source_only ? get_sources(results) : result
    end

    def move(source, dest, query)
      per = 30000
      source_client = Elasticsearch::Client.new hosts: source, index: @index, logger: @logger
      dest_client = Elasticsearch::Client.new hosts: dest, logger: @logger
      num = 0
      while true
        from = num * per
        body = { size: per, from: from }
        body[:query] = { query_string: { query: query } } unless query.nil?
        data = Hashie::Mash.new(source_client.search index: @index, body: body)
        break if data.hits.hits.empty?
        bulk_message = []
        data.hits.hits.each do |doc|
          bulk_message << { 'index' => { '_index' => doc._index, '_type' => doc._type, '_id' => doc._id } }
          bulk_message << doc._source
        end
        dest_client.bulk body: bulk_message unless bulk_message.empty?
        num += 1
      end
    end

    def dump(query)
      per = 30000
      num = 0
      bulk_message = []
      while true
        from = num * per
        body = { size: per, from: from }
        body[:query] = { query_string: { query: query } } unless query.nil?
        data = Hashie::Mash.new(@client.search index: @index, body: body)
        break if data.hits.hits.empty?
        data.hits.hits.each do |doc|
          source = doc.delete('_source')
          doc.delete('_score')
          bulk_message << Yajl::Encoder.encode({ 'index' => doc.to_h })
          bulk_message << Yajl::Encoder.encode(source)
        end
        num += 1
      end
      puts bulk_message.join("\n")
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

    def aliases
      @client.indices.get_aliases
    end

    def health
      @client.cluster.health
    end

    def state
      @client.cluster.state
    end

    def indices
      @client.cat.indices format: 'json'
    end

    def count
      @client.cat.count index: @index, format: 'json'
    end

    def stats
      @client.indices.stats index: @index
    end

    def put_mapping(index, type, body)
      @client.indices.create index: index unless @client.indices.exists index: index
      @client.indices.put_mapping index: index, type: type, body: body
    end

    def mapping
      data = @client.indices.get_mapping index: @index
      @index == '_all' ? data : data[@index]['mappings']
    end

    def put_template(name, hash)
      @client.indices.put_template name: name, body: hash
    end

    def create_aliases(als, indices)
      actions = []
      indices.each do |index|
        actions << { add: { index: index, alias: als } }
      end
      @client.indices.update_aliases body: {
        actions: actions
      }
    end

    def recovery
      @client.indices.recovery index: @index
    end

    def delete(index, query)
      if query.nil?
        @client.indices.delete index: index
      else
        @client.delete_by_query index: index, q: query
      end
    end

    def template
      @client.indices.get_template
    end

    def delete_template(name)
      @client.indices.delete_template name: name
    end

    def settings
      @client.indices.get_settings
    end

    def warmer
      @client.indices.get_warmer index: @index
    end

    def refresh
      @client.indices.refresh index: @index
    end

    def bulk(timestamp_key, type, add_timestamp, id_keys, index)
      data = parse_json(STDIN.read)
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
        meta[:index][:_id] = generate_id(template, record, id_keys) unless id_keys.nil?
        bulk_message << meta
        bulk_message << record
      end
      bulk_message.in_groups_of(10000, false) do |block|
        @client.bulk body: block
      end
    end

    private

    def parse_json(buffer)
      begin
        data = Yajl::Parser.parse(buffer)
      rescue => e
        data = []
        buffer.split("\n").each do |line|
          data << Yajl::Parser.parse(line)
        end
      end
      data.class == Array ? data : [data]
    end

    def generate_id(template, record, id_keys)
      template % id_keys.map { |key| record[key] }
    end

    def get_sources(results)
      results.hits.hits.map { |result| result._source }
    end

  end
end
