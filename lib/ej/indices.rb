module Ej
  class Indices
    def initialize(values)
      @logger =  values.logger
      @index = values.index
      @client = values.client
    end

    def aliases
      @client.indices.get_aliases
    end

    def indices
      @client.cat.indices format: 'json'
    end

    def stats
      @client.indices.stats index: @index
    end

    def put_template(name, hash)
      @client.indices.put_template name: name, body: hash
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

    def put_mapping(index, type, body)
      @client.indices.create index: index unless @client.indices.exists index: index
      @client.indices.put_mapping index: index, type: type, body: body
    end

    def mapping
      data = @client.indices.get_mapping index: @index
      @index == '_all' ? data : data[@index]['mappings']
    end

    def delete(index, type, query)
      if query.nil?
        if type.nil?
          @client.indices.delete index: index
        else
          body = {
            query: {
              match_all: {}
            }
          }
          @client.delete_by_query index: index, type: type, body: body
        end
      else
        body = {
          query: {
            match: query
          }
        }
        @client.delete_by_query index: index, body: body
      end
    end

    def template
      @client.indices.get_template
    end

    def delete_template(name)
      @client.indices.delete_template name: name
    end

    def settings
      @client.indices.get_settings
    end

    def warmer
      @client.indices.get_warmer index: @index
    end

    def refresh
      @client.indices.refresh index: @index
    end
  end
end
