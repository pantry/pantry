module Pantry

  # A Null Object for any Process listener type object used throughout the system.
  # All processes that want to utilize a progress listener has the following methods
  # available to them. See Pantry::Communication::SendFile for an example process
  # that uses a listener to notify of file upload progress.
  class ProgressListener

    # Trigger the start of a multi-step process. The number of steps
    # should be given as +progress_size+
    def start_progress(progress_size)
    end

    # Note that the process in question has stepped forward, allowing
    # any progress tracking to move the appropriate amount.
    def step_progress(step_amount)
    end

    # Do something with the given message, normally a String.
    # Basically a way to notify that something is happening.
    def say(message)
    end

    # Notify that an error occurred in the process.
    def error(message)
    end

    # Notify that the process is finished.
    def finished
    end

    def wait_for_finish
    end

  end

end
