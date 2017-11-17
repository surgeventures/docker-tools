#!/usr/bin/env ruby

require 'yaml'
require 'socket'

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

    def wait_for_port(value)
      host, port = value.split(":")
      puts "Waiting for port #{port} on host '#{host}'"
      begin
        Socket.tcp(host, port.to_i, connect_timeout: 30) { true }
      rescue
        false
      end
    end

    def run(cmd)
      puts "Running '#{cmd}'"
      system(cmd)
    end
  end
end

Runner.call
