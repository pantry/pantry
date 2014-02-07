module Pantry

  def self.ui(input = $stdin, output = $stdout)
    @@ui ||= Pantry::UI.new(input, output)
  end

  def self.reset_ui!
    @@ui = nil
  end

  class UI

    def initialize(input = $stdin, output = $stdout)
      require 'highline'
      @highline = HighLine.new(input, output)
    end

    # Send a message to STDOUT
    def say(message)
      @highline.say(message)
    end

    # Print out a list, attempting to make it look somewhat reasonable
    def list(array)
      array.each do |entry|
        say([entry].flatten.join(" -- "))
      end
    end

    # Show the user a message and ask them to continue by hitting Enter,
    # or they can cancel with "No"
    def continue?(message)
      @highline.agree(message) do |q|
        q.default = "yes"
      end
    end

  end
end
