module Runner
  class WaitStep
    class << self
      def call(secs_string)
        secs = secs_string.to_i
        puts "Waiting #{secs} sec(s)"
        sleep secs
      end
    end
  end
end
