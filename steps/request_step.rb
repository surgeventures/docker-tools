require 'open-uri'

module Runner
  class RequestStep
    class << self
      def call(url)
        puts "Requesting '#{url}'"

        (1..300).find do
          sleep 1
          open(url, read_timeout: 1) rescue false
        end.tap do |success|
          puts "Failure requesting '#{url}'" unless success
        end
      end
    end
  end
end
