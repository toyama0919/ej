module Ej
  class Cluster
    def initialize(values)
      @logger =  values.logger
      @index = values.index
      @client = values.client
    end

    def health
      @client.cluster.health
    end

    def state
      @client.cluster.state
    end
  end
end
