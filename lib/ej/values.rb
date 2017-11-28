module Ej
  class Values
    attr_reader :client
    attr_reader :index
    attr_reader :logger

    def initialize(global_options)
      @logger =  Logger.new($stderr)
      @logger.level = global_options[:debug] ? Logger::DEBUG : Logger::INFO
      @client = get_client(global_options[:host], global_options[:index], global_options[:user], global_options[:password])
      @index = global_options[:index]
    end

    def get_client(host_string, index, user, password)
      hosts = Util.parse_hosts(host_string, user, password)
      ::Elasticsearch::Client.new transport: Util.get_transport(hosts), index: index, logger: @logger
    end
  end
end
