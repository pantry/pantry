module Pantry

  # Global access to Pantry's UI handler. This object offers up
  # a set of methods used to interact with the User via the CLI.
  def self.ui(input = $stdin, output = $stdout)
    @@ui ||= Pantry::UI.new(input, output)
  end

  def self.reset_ui!
    @@ui = nil
  end

  class UI

    def initialize(input = $stdin, output = $stdout)
      require 'highline'
      @output = output
      @input  = input
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

    # Start a new progress meter with the given number of ticks
    def progress_start(tick_count)
      require 'ruby-progressbar'
      @progress = ProgressBar.create(
        total: tick_count, output: @output,
        format: "Progress: %P%% |%B| %c/%C %e"
      )
    end

    # Increment the running progress meter the given number of ticks
    def progress_step(tick_count)
      if @progress.progress + tick_count > @progress.total
        tick_count = @progress.total - @progress.progress
      end

      @progress.progress += tick_count
    end

    # Complete and close down the current progress meter
    def progress_finish
      @progress.finish
    end

  end
end
