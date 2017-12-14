require 'socket'
require 'uri'

module Runner
  class WaitForPortStep
    class << self
      def call(url)
        host, port = url.split(":")
        puts "Waiting for port #{port} on host '#{host}'"

        (1..300).find do
          sleep 1
          Socket.tcp(host, port.to_i, connect_timeout: 1) { true } rescue false
        end.tap do |success|
          puts "Failure waiting for port #{port} on host '#{host}'" unless success
        end
      end
    end
  end
end
