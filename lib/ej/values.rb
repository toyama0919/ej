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

    def get_client(host, index)
      host, port = host.split(':')
      transport = ::Elasticsearch::Transport::Transport::HTTP::Faraday.new(
        {
          hosts: [{ host: host, port: port }],
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
