module Pantry
  module Communication

    # The WaitList manages futures for asynchronously waiting for responses
    # from either the Client or the Server. Given an identity and a message,
    # WaitList returns a Future that will be filled when the handler in question
    # receives a message of the same Message type from that identity.
    class WaitList

      def initialize
        @futures = Hash.new {|hash, key| hash[key] = []}
      end

      # Given a +message+ being sent, create a Future for a response to this message.
      # This keys off of the Message's UUID, which must be kept in tact as it
      # passes through the system.
      def wait_for(message)
        future = Celluloid::Future.new
        @futures[ message.uuid ] << future
        future
      end

      # Is there a future waiting for this response message?
      def waiting_for?(message)
        !@futures[ message.uuid ].empty?
      end

      # Internal to Celluloid::Future, using #signal ends up in a Result object
      # in which calling #value then calls #value on the saved data which in our
      # case is Message. We just want the Message so wrap up our messages in this
      # object to work around this oddity.
      #
      # https://github.com/celluloid/celluloid/blob/master/lib/celluloid/future.rb#L89
      FutureResultWrapper = Struct.new(:value)

      def received(message)
        if future = @futures[ message.uuid ].shift
          future.signal(FutureResultWrapper.new(message))
        end
      end

    end

  end
end
