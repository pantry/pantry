module Pantry

  # This ProgressListener outputs progress notification to the command
  # line. It also takes a future that will be triggered once the command
  # is finished. This ensures that the command line process itself stays
  # running until the requested command has run fully.
  class CLIProgressListener < ProgressListener

    def initialize
      @finish_future = Celluloid::Future.new
    end

    def start_progress(count)
      Pantry.logger.info("[CLI PF] Starting progress: #{count} bytes")
    end

    def step_progress(step)
      Pantry.logger.info("[CLI PF] Just sent #{step} bytes")
    end

    def say(message)
      Pantry.logger.info("[CLI] #{message.inspect}")
    end

    def error(message)
      Pantry.logger.error("[CLI PF] We gots an ERROR! #{message.inspect}")
    end

    def finished
      Pantry.logger.info("[CLI PF] We are done")
      @finish_future.signal(OpenStruct.new(:value => self))
    end

    def wait_for_finish
      @finish_future.value
    end

  end
end
