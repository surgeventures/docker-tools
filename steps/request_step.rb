require 'open-uri'

module Runner
  class RequestStep
    class << self
      def call(url)
        puts "Requesting '#{url}'"
        open(url, read_timeout: 60 * 5)
        true
      end
    end
  end
end
