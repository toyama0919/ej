#!/usr/bin/env ruby
# coding: utf-8
require 'thor'
require 'yajl'
require 'elasticsearch'
require 'esq/core'
require 'active_support/core_ext/array'
require 'active_support/core_ext/string'
require 'logger'

module Esq
  class Commands < Thor
    class_option :index, aliases: '-i', type: :string, default: '_all', desc: 'profile by .database.yml'
    class_option :host, aliases: '-h', type: :string, default: "localhost", desc: 'host'
    class_option :profile, aliases: '-p', type: :string, default: 'default', desc: 'profile by .database.yml'
    class_option :pretty, aliases: '-P', type: :boolean, default: false, desc: 'pretty print'
    map '-s' => :search
    map '-c' => :facet
    map '-I' => :bulk
    map '-l' => :indices
    map '-a' => :aliases
    map '-m' => :mapping
    map '--health' => :health

    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options
      @core = Esq::Core.new(@global_options['host'], @global_options['index'])
    end

    desc '-s [table name]', 'count record, group by keys'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    option :from, type: :numeric, aliases: '--from', default: 0, desc: 'from'
    def search(query = nil)
      puts_json(@core.search(options['type'], query, options['size'], options['from']))
    end

    desc '-s [table name]', 'count record, group by keys'
    option :source, type: :string, aliases: '--source', desc: 'from'
    option :dest, type: :string, aliases: '--dest', desc: 'from'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def dump
      @core.dump(options['source'], options['dest'], options['query'])
    end

    desc '-c [table name] -k [group by keys]', 'count record, group by keys'
    option :query, type: :string, aliases: '-q', default: '', desc: 'query'
    option :filter, type: :hash, aliases: '--filter', default: {}, desc: 'facet filter'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    def facet
      puts_json(@core.facet(options['term'], options['size'], options['filter']))
    end

    desc '-c [table name] -k [group by keys]', 'count record, group by keys'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def min
      puts_json(@core.min(options['term']))
    end

    desc '-c [table name] -k [group by keys]', 'count record, group by keys'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def max
      puts_json(@core.max(options['term']))
    end

    desc '-I INDEX/TYPE', 'bulk api'
    option :timestamp_key, aliases: '--timestamp_key', type: :string, desc: 'timestamp key', default: nil
    option :add_timestamp, type: :boolean, default: true, desc: 'add_timestamp'
    option :type, type: :string, aliases: '-t', default: nil, required: true, desc: 'type'
    option :id_keys, type: :array, aliases: '--id', default: nil, desc: 'id'
    def bulk
      @core.bulk(options['timestamp_key'], options['type'], options['add_timestamp'], options['id_keys'])
    end

    desc 'health', 'health'
    def health
      puts_json(@core.health)
    end

    desc 'list aliases', 'health'
    def aliases
      puts_json(@core.aliases)
    end

    desc 'state', 'health'
    def state
      puts_json(@core.state)
    end

    desc 'indices', 'health'
    def indices
      puts_json(@core.indices)
    end

    desc 'count', 'count'
    def count
      puts_json(@core.count)
    end

    desc 'count', 'count'
    def stats
      puts_json(@core.stats)
    end

    desc 'mapping', 'count'
    def mapping
      puts_json(@core.mapping)
    end

    desc 'mapping', 'count'
    option :type, type: :string, aliases: '-t', default: nil, required: true, desc: 'type'
    def not_analyzed
      puts_json(@core.not_analyzed(options['type']))
    end

    desc 'mapping', 'count'
    option :alias, type: :string, aliases: '-a', default: nil, required: true, desc: 'type'
    option :indices, type: :array, aliases: '-x', default: nil, required: true, desc: 'type'
    def create_aliases
      @core.create_aliases(options['alias'], options['indices'])
    end

    desc 'mapping', 'count'
    def recovery
      @core.recovery
    end

    private

    def puts_json(object)
      puts Yajl::Encoder.encode(object, pretty: @global_options['pretty'])
    end
  end
end
