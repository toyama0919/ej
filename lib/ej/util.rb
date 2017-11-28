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

    def self.get_transport(hosts)
      transport = ::Elasticsearch::Transport::Transport::HTTP::Faraday.new(
        {
          hosts: hosts,
          options: {
            reload_connections: true,
            reload_on_failure: false,
            retry_on_failure: 5,
            transport_options: {
              headers: { 'Content-Type' => 'application/json' },
              request: { timeout: 300 }
            }
          }
        }
      )
      return transport
    end

    def self.parse_hosts(host_string, user = nil, password = nil)
      host, port = (host_string || DEFAULT_HOST), DEFAULT_PORT
      if !host_string.nil? && host_string.include?(":")
        host, port = host_string.split(':')
      end

      hosts = [{ host: host, port: port.to_i, user: user, password: password }]
      return hosts
    end
  end
end
