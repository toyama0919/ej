require 'ej/core'
require 'thor'
require 'yajl'

module Ej
  class Commands < Thor
    class_option :index, aliases: '-i', type: :string, default: '_all', desc: 'index'
    class_option :host, aliases: '-h', type: :string, default: DEFAULT_HOST, desc: 'host'
    class_option :debug, aliases: '-d', type: :boolean, default: false, desc: 'debug mode'

    map '-s' => :search
    map '-f' => :facet
    map '-c' => :count
    map '-b' => :bulk
    map '-l' => :indices
    map '-a' => :aliases
    map '-m' => :mapping
    map '--health' => :health
    map '-v' => :version

    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options
      values = Values.new(@global_options)
      @core = Ej::Core.new(values)
      @indices = Ej::Indices.new(values)
      @cluster = Ej::Cluster.new(values)
      @nodes = Ej::Nodes.new(values)
    end

    desc '-s [lucene query]', 'search'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :size, type: :numeric, aliases: '-n', default: nil, desc: 'size'
    option :from, type: :numeric, aliases: '--from', default: 0, desc: 'from'
    option :fields, type: :array, aliases: '--fields', default: nil, desc: 'fields'
    option :meta, type: :boolean, default: false, desc: 'meta'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    option :sort, type: :hash, aliases: '--sort', default: nil, desc: 'ex. --sort @timestamp:desc'
    def search(query = options[:query])
      puts_with_format(@core.search(options[:type],
                             query,
                             options[:size],
                             options[:from],
                             options[:meta],
                             nil,
                             options[:fields],
                             options[:sort]
                             ))
    end

    desc 'total [lucene query]', 'total'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def count(query = options[:query])
      puts_with_format(@core.search(options[:type], query, 0, 0, false))
    end

    desc 'distinct [lucene query]', 'distinct'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def distinct(term)
      puts_with_format(@core.distinct(term, options[:type], options[:query]))
    end

    desc 'copy', 'copy index'
    option :source, type: :string, aliases: '--source', required: true, desc: 'source host'
    option :dest, type: :string, aliases: '--dest', required: true, desc: 'dest host'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    option :per, type: :numeric, default: nil, desc: 'per'
    option :scroll, type: :string, default: "1m", desc: 'scroll'
    def copy
      @core.copy(
        options[:source],
        options[:dest],
        options[:query],
        options[:per],
        options[:scroll]
      )
    end

    desc 'dump', 'dump index'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    option :per, type: :numeric, default: nil, desc: 'per'
    def dump
      @core.dump(options[:query], options[:per])
    end

    desc '-f', 'facet'
    option :query, type: :string, aliases: '-q', default: '*', desc: 'query'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    def facet(term)
      puts_with_format(@core.facet(term, options[:size], options[:query]))
    end

    desc 'aggs', 'aggs'
    option :query, type: :string, aliases: '-q', default: '*', desc: 'query'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    option :terms, type: :array, aliases: '-t', required: true, desc: 'size'
    def aggs
      puts_with_format(@core.aggs(options[:terms], options[:size], options[:query]))
    end

    desc 'min', 'term'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def min
      puts_with_format(@core.min(options[:term]))
    end

    desc 'max', 'count record, group by keys'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def max
      puts_with_format(@core.max(options[:term]))
    end

    desc '-b', 'bulk import JSON'
    option :index, aliases: '-i', type: :string, default: "logstash-#{Time.now.strftime('%Y.%m.%d')}", required: true, desc: 'index'
    option :type, type: :string, aliases: '-t', default: nil, required: true, desc: 'type'
    option :timestamp_key, aliases: '--timestamp_key', type: :string, desc: 'timestamp key', default: nil
    option :add_timestamp, type: :boolean, default: true, desc: 'add_timestamp'
    option :id_keys, type: :array, aliases: '--id', default: nil, desc: 'id'
    option :inputs, type: :array, aliases: '--inputs', default: [], desc: 'input files path.'
    def bulk
      inputs = options[:inputs].empty? ? [STDIN] : options[:inputs]
      inputs.each do |key|
        buffer = (key.class == STDIN.class) ? STDIN.read : File.read(key)
        @core.bulk(
          options[:timestamp_key],
          options[:type],
          options[:add_timestamp],
          options[:id_keys],
          options[:index],
          Util.parse_json(buffer)
        )
      end
    end

    desc 'health', 'health'
    def health
      puts_with_format(@cluster.health)
    end

    desc '-a', 'list aliases'
    def aliases
      puts_with_format(@indices.aliases)
    end

    desc 'state', 'state'
    def state
      puts_with_format(@cluster.state)
    end

    desc 'indices', 'show indices summary'
    def indices
      puts_with_format(@indices.indices)
    end

    desc 'stats', 'index stats'
    def stats
      puts_with_format(@indices.stats)
    end

    desc 'mapping', 'show mapping'
    def mapping
      puts_with_format(@indices.mapping)
    end

    desc 'not_analyzed', 'not analyzed'
    def not_analyzed
      json = File.read(File.expand_path('../../../template/not_analyze_template.json', __FILE__))
      hash = Yajl::Parser.parse(json)
      puts_with_format(@indices.put_template('ej_init', hash))
    end

    desc 'put_routing', "put routing.\nexsample. ej put_routing -i someindex -t sometype --path somecolumn"
    option :index, aliases: '-i', type: :string, default: nil, required: true, desc: 'index'
    option :type, aliases: '-t', type: :string, default: nil, required: true, desc: 'type'
    option :path, type: :string, default: nil, required: true, desc: 'path'
    def put_routing
      body = { options[:type] => {"_routing"=>{"required"=>true, "path"=>options[:path]}}}
      puts_with_format(@indices.put_mapping(options[:index], options[:type], body))
    end

    desc 'put_template', 'put template'
    def put_template(name)
      hash = Yajl::Parser.parse(STDIN.read)
      puts_with_format(@indices.put_template(name, hash))
    end

    desc 'create_aliases', 'create aliases'
    option :alias, type: :string, aliases: '-a', default: nil, required: true, desc: 'alias name'
    option :indices, type: :array, aliases: '-x', default: nil, required: true, desc: 'index array'
    def create_aliases
      @indices.create_aliases(options[:alias], options[:indices])
    end

    desc 'recovery', 'recovery'
    def recovery
      @indices.recovery
    end

    desc 'delete', 'delete'
    option :index, aliases: '-i', type: :string, default: nil, required: true, desc: 'index'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def delete
      query = options[:query] ? eval(options[:query]) : nil
      @indices.delete(options[:index], options[:type], query)
    end

    desc 'delete_template --name [name]', 'delete_template'
    option :name, type: :string, default: nil, required: true, desc: 'template name'
    def delete_template
      @indices.delete_template(options[:name])
    end

    desc 'template', 'show template'
    def template
      puts_with_format(@indices.template)
    end

    desc 'settings', 'show template'
    def settings
      puts_with_format(@indices.settings)
    end

    desc 'warmer', 'warmer'
    def warmer
      puts_with_format(@indices.warmer)
    end

    desc 'refresh', 'refresh'
    def refresh
      puts_with_format(@indices.refresh)
    end

    desc 'nodes_info', 'view nodes info'
    def nodes_info
      puts_with_format @nodes.nodes_info
    end

    desc 'nodes_stats', 'view nodes stats'
    def nodes_stats
      puts_with_format @nodes.nodes_stats
    end

    desc '-v', 'show version'
    def version
      puts VERSION
    end

    private

    def puts_with_format(object)
      puts Yajl::Encoder.encode(object, pretty: true)
    end

  end
end
