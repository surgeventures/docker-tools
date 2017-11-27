#!/usr/bin/env ruby

require 'yaml'
require 'socket'
require 'pty'
require 'uri'

Termination = Class.new(Exception)

class Runner
  class << self
    def call
      steps = YAML.load(ARGV.first)

      process_steps(steps) ? exit(0) : exit(1)
    end

    private

    def process_steps(steps)
      steps.all? do |step|
        process_step(step)
      end
    end

    def process_step(step)
      type = step.keys[0]
      value = step.values[0]

      case type
      when "all"
        all(value)
      when "run"
        run(value)
      when "wait"
        wait(value)
      when "wait_for_port"
        wait_for_port(value)
      when "wait_for_postgres"
        wait_for_postgres(value)
      else
        raise "unknown step: #{type.inspect}"
      end
    end

    def all(steps)
      steps.reject do |step|
        process_step(step)
      end.empty?
    end

    def wait(value)
      secs = value.to_i
      puts "Waiting #{secs} sec(s)"
      sleep secs
    end

    def wait_for_port(value)
      host, port = value.split(":")
      puts "Waiting for port #{port} on host '#{host}'"

      (1..30).find do
        Socket.tcp(host, port.to_i, connect_timeout: 1) { true } rescue false
        sleep 1
      end.tap do |success|
        puts "Failure waiting for port #{port} on host '#{host}'" unless success
      end
    end

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

    def wait_for_postgres(url)
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

    def run(cmd)
      puts "Running '#{cmd}'"

      PTY.spawn(cmd) do |stdout, _, pid|
        begin
          stdout.each { |line| print line }
        rescue Termination
          puts "Sending SIGTERM to #{pid}"
          Process.kill("TERM", pid)
          stdout.each { |line| print line }
        end
      end

      puts "Failure with status #{$?.exitstatus} from '#{cmd}'" unless $?.success?

      $?.success?
    end
  end
end

Signal.trap("TERM") do
  raise(Termination)
end

Runner.call
