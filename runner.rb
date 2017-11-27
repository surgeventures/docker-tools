#!/usr/bin/env ruby

require 'yaml'
require 'socket'
require 'timeout'
require 'pty'

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
