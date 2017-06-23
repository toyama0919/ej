module Ej
  class Values
    attr_reader :client
    attr_reader :index
    attr_reader :logger

    def initialize(global_options)
      @logger =  Logger.new($stderr)
      @logger.level = global_options[:debug] ? Logger::DEBUG : Logger::INFO
      @client = get_client(global_options[:host], global_options[:index])
      @index = global_options[:index]
    end

    def get_client(host_string, index)
      host, port = (host_string || DEFAULT_HOST), DEFAULT_PORT
      if !host_string.nil? && host_string.include?(":")
        host, port = host_string.split(':')
      end

      hosts = [{ host: host, port: port }]
      transport = ::Elasticsearch::Transport::Transport::HTTP::Faraday.new(
        {
          hosts: hosts,
          options: {
            reload_connections: true,
            reload_on_failure: false,
            retry_on_failure: 5,
            transport_options: {
              request: { timeout: 300 }
            }
          }
        }
      )
      ::Elasticsearch::Client.new transport: transport, index: index, logger: @logger
    end
  end
end
