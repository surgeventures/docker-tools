require 'pty'

module Runner
  class RunStep
    class << self
      def call(cmd)
        $stdout.sync = true

        puts "Running '#{cmd}'"

        status = nil

        PTY.spawn(cmd) do |stdout, _, pid|
          begin
            print_output(stdout)
          rescue Termination
            puts "Sending SIGTERM to #{pid}"
            status = "Termination"
            Process.kill("TERM", pid)
            print_output(stdout)
          rescue Interrupt
            puts "Sending SIGINT to #{pid}"
            status = "Interrput"
            Process.kill("INT", pid)
            print_output(stdout)
          rescue Errno::EIO
            nil
          end

          Process.wait(pid)
        end

        if status
          puts "#{status} during '#{cmd}'"
          false
        elsif !$?.success?
          puts "Failure with status #{$?.exitstatus} from '#{cmd}'"
          false
        else
          true
        end
      end

      private

      def print_output(stdout)
        stdout.each_char { |char| putc char }
      end
    end
  end
end
