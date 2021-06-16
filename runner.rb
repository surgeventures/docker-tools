#!/usr/bin/env ruby

require 'yaml'
require_relative './steps/run_step'
require_relative './steps/wait_for_amqp_step'
require_relative './steps/wait_for_port_step'
require_relative './steps/wait_for_postgres_step'
require_relative './steps/wait_step'
require_relative './steps/request_step'

Termination = Class.new(Exception)

module Runner
  class Main
    class << self
      def call
        Signal.trap("TERM") do
          raise(Termination)
        end

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
          RunStep.call(value)
        when "wait"
          WaitStep.call(value)
        when "wait_for_amqp"
          WaitForAmqpStep.call(value)
        when "wait_for_port"
          WaitForPortStep.call(value)
        when "wait_for_postgres"
          WaitForPostgresStep.call(value)
        when "request"
          RequestStep.call(value)
        else
          raise "unknown step: #{type.inspect}"
        end
      end

      def all(steps)
        steps.reject do |step|
          process_step(step)
        end.empty?
      end
    end
  end
end

Runner::Main.call
