#!/usr/bin/env ruby
# coding: utf-8
require 'yaml'
require 'yajl'
require 'elasticsearch'
require 'hashie'
require 'pp'

module Esq
  class Core

    def initialize(host, index)
      @logger =  Logger.new($stderr)
      @logger.level = Logger::INFO
      @index = index
      @client = Elasticsearch::Client.new hosts: host, logger: @logger, index: @index
    end

    def search(type, query, size, from)
      body = { size: size, from: from }
      body[:query] = { query_string: { query: query } } unless query.nil?
      @client.search index: @index, type: type, body: body
    end

    def dump(source, dest, query)
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
        data.hits.hits.each { |doc|
          bulk_message << { 'index' => { '_index' => doc._index, '_type' => doc._type, '_id' => doc._id } }
          bulk_message << doc._source
        }
        dest_client.bulk body: bulk_message unless bulk_message.empty?
        num += 1
      end
    end

    def facet(term, size, filter)
      body = {
        query: {
          match_all: {}
        },
        facets: {
          term => { terms: {field: term, size: size} }
        }
      }
      @client.search index: @index, body: body, size: 0
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

    def mapping
      data = @client.indices.get_mapping index: @index
      @index == '_all' ? data : data[@index]['mappings']
    end

    def not_analyzed(type)
      data = Hashie::Mash.new(@client.indices.get_mapping index: @index, type: type)
      data[@index].mappings[type]
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

    def bulk(timestamp_key, type, add_timestamp, id_keys)
      data = parse_json(STDIN.read)
      template = id_keys.map { |key| '%s' }.join('_')
      bulk_message = []
      data.each do |record|
        if timestamp_key.nil?
          timestamp = Time.now.to_datetime.to_s
        else
          timestamp = record[timestamp_key].to_time.to_datetime.to_s
        end
        record.merge!( '@timestamp' => timestamp) if add_timestamp
        meta = { index: { _index: @index, _type: type } }
        meta[:index][:_id] = generate_id(template, record, id_keys)
        bulk_message << meta
        bulk_message << record
      end
      bulk_message.in_groups_of(10000, false) do |block|
        @client.bulk body: block
      end
    end

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
      template % id_keys.map{ |key| record[key] }
    end
  end
end
