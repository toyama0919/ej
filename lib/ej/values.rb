module Ej
  class Values
    attr_reader :client
    attr_reader :index
    attr_reader :logger

    def initialize(global_options)
      @logger =  Logger.new($stderr)
      @logger.level = global_options[:debug] ? Logger::DEBUG : Logger::INFO
      @client = Elasticsearch::Client.new(
        hosts: global_options[:host],
        logger: @logger,
        index: global_options[:index]
      )
      @index = global_options[:index]
    end
  end
end
