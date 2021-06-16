require "socket"
require "uri"

module Runner
  class WaitForAmqpStep
    class << self
      def call(url)
        uri = url =~ /^amqp:\/\// ? URI.parse(url) : URI.parse("amqp://#{url}")
        host = uri.host
        port = uri.port || 5672
        final_url = "#{host}:#{port}"

        puts "Waiting for AMQP on '#{final_url}'"

        30.times do
          return true if amqp_ready_for_query?(host, port)

          sleep 1
        end

        puts "Failure waiting for AMQP on '#{final_url}'"
      end

      private

      def amqp_ready_for_query?(host, port)
        # Connect to AMQP and send Preamble packet
        socket = TCPSocket.new(host, port)
        socket.write("AMQP\x00\x00\x09\x01")

        # Read initial response attributes
        type, channel, length, klass, amqp_method = socket.read(11).unpack("C S> L> S> S>")

        # Type == 1 means Method
        # Class == 10 means Connection
        # Method == 10 means Start
        if [type, klass, amqp_method] == [1, 10, 10]
          return true
        end

        false
      rescue Errno::ECONNREFUSED => error
        false
      ensure
        socket.close if socket
      end
    end
  end
end
