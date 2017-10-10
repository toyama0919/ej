module Ej
  class Util
    def self.parse_json(buffer)
      begin
        data = JSON.parse(buffer)
      rescue => e
        data = []
        buffer.lines.each do |line|
          data << JSON.parse(line)
        end
      end
      data.class == Array ? data : [data]
    end

    def self.generate_id(template, record, id_keys)
      template % id_keys.map { |key| record[key] }
    end

    def self.get_sources(results)
      results.hits.hits.map { |result| result._source }
    end
  end
end
