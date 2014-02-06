module Pantry

  def self.ui
    @@ui ||= Pantry::UI.new
  end

  def self.reset_ui!
    @@ui = nil
  end

  class UI

    def initialize
      require 'highline'
      @highline = HighLine.new
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
