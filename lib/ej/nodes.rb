module Ej
  class Nodes
    def initialize(values)
      @logger =  values.logger
      @index = values.index
      @client = values.client
    end

    def nodes_info
      @client.nodes.info
    end

    def nodes_stats
      @client.nodes.stats
    end
  end
end
