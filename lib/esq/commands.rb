#!/usr/bin/env ruby
# coding: utf-8
require 'thor'
require 'yajl'
require 'elasticsearch'
require 'esq/core'
include Esq::Core

module Esq
  class Commands < Thor
    class_option :profile, aliases: '-p', type: :string, default: 'default', desc: 'profile by .database.yml'
    class_option :pretty, aliases: '-P', type: :boolean, default: false, desc: 'pretty print'
    map '-s' => :sample
    map '-c' => :facet
    map '-I' => :bulk

    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options
      @client = Elasticsearch::Client.new :hosts => '127.0.0.1'
    end

    desc '-s [table name] -k [group by keys]', 'count record, group by keys'
    option :query, type: :string, aliases: '-q', default: '', desc: 'query'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    option :from, type: :numeric, aliases: '--from', default: 0, desc: 'from'
    def sample(index_and_type)
      target_index, type_name = index_and_type.split('/')
      body = { query: { query_string: { query: options['query'] } }, size: options['size'] }
      results = @client.search index: target_index, body: body
      puts Yajl::Encoder.encode(results, pretty: @global_options['pretty'])
    end

    desc '-s [table name] -k [group by keys]', 'count record, group by keys'
    option :query, type: :string, aliases: '-q', default: '', desc: 'query'
    option :terms, type: :array, aliases: '-t', desc: 'terms'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    def facet(index_and_type)
      target_index, type_name = index_and_type.split('/')
      body = {
          query: {
              match_all: {  }
          },
          facets: {
              facet: {
                  terms: {
                      fields: options['terms'],
                      size: options['size'],
                  }
              }
          },
          size: 0
      }
      results = @client.search index: target_index, body: body
      puts Yajl::Encoder.encode(results, pretty: @global_options['pretty'])
    end

    desc '-I INDEX/TYPE', 'bulk api'
    def bulk(index_and_type)
      data = Yajl::Parser.parse(STDIN)
      target_index, type_name = index_and_type.split('/')
      bulk_message = []
      data.each do |record|
        record.merge!({"@timestamp" => Time.now.to_datetime.to_s})
        meta = { "index" => {"_index" => target_index, "_type" => type_name} }
        bulk_message << meta
        bulk_message << record
      end
      @client.bulk body: bulk_message
    end

    private

    # def client
    #   @_es ||= Elasticsearch::Client.new :hosts => localhost, :reload_connections => true, :adapter => :patron, :retry_on_failure => 5
    #   raise "Can not reach Elasticsearch cluster (#{@host}:#{@port})!" unless @_es.ping
    #   @_es
    # end
  end
end
