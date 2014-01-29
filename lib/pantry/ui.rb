module Pantry

  def self.ui
    @@ui ||= Pantry::UI.new
  end

  class UI

    def initialize
      require 'highline'
      @highline = HighLine.new
    end

    def say(message)
      @highline.say(message)
    end

    def list(array)
      array.each do |entry|
        say([entry].flatten.join(" -- "))
      end
    end

  end
end
