require 'socket'
require 'uri'

module Runner
  class WaitForPostgresStep
    class << self
      def call(url)
        uri = URI.parse("postgres://#{url}")
        user = uri.user || "postgres"
        host = uri.host
        port = uri.port || 5432
        final_url = "#{user}@#{host}:#{port}"

        puts "Waiting for Postgres on '#{final_url}'"

        30.times do
          return true if postgres_ready_for_query?(host, port, user)

          sleep 1
        end

        puts "Failure waiting for Postgres on '#{final_url}'"
      end

      private

      def postgres_ready_for_query?(host, port, user)
        # Generate Startup packet:
        # - packet size (Integer, 4 bytes)
        # - version (Integer, 4 bytes)
        # - name/value pairs (user is required)
        # - null terminator
        size = user.size + 15
        startup_packet = [size, 196608, "user", user, 0].pack("L>L>Z*Z*C").freeze

        # Generate ReadyForQuery packet:
        # - message type ("Z", 1 byte)
        # - packet size (5, 4 bytes)
        # - transaction status (1 byte)
        #   - "I" = Idle
        #   - "T" = In transaction block
        #   - "E" = In failed transaction block
        ready_for_query_packet = [90, 5, 73].pack("CL>C").freeze

        # Connect to Postgres and send Startup packet
        socket = TCPSocket.new(host, port)
        socket.write(startup_packet)

        response = ""

        # Wait for ReadyForQuery packet
        while char = socket.getc
          response << char

          return true if response[-6..-1] == ready_for_query_packet
        end

        false
      rescue Errno::ECONNREFUSED
        false
      end
    end
  end
end
