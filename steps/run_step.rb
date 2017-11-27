require 'pty'

module Runner
  class RunStep
    class << self
      def call(cmd)
        puts "Running '#{cmd}'"

        status = nil
        PTY.spawn(cmd) do |stdout, _, pid|
          begin
            stdout.each { |line| print line }
          rescue Termination
            puts "Sending SIGTERM to #{pid}"
            status = "Termination"
            Process.kill("TERM", pid)
            stdout.each { |line| print line }
          rescue Interrupt
            puts "Sending SIGINT to #{pid}"
            status = "Interrput"
            Process.kill("INT", pid)
            stdout.each { |line| print line }
          end
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
    end
  end
end
