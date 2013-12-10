module Pantry
  module Communication

    # The WaitList manages futures for asynchronously waiting for responses
    # from either the Client or the Server. Given an identity and a message,
    # WaitList can wait for a single response to a single message or can be
    # asked to handle a stream of messages to a specific receiver object.
    class WaitList

      def initialize
        @receivers = {}
      end

      # Given a +message+ being sent, create a Future for a response to this message.
      # This keys off of the Message's UUID, which must be kept in tact as it
      # passes through the system.
      def wait_for(message)
        receiver = OneShotReceiver.new(message)
        @receivers[ message.uuid ] = receiver
        receiver.future
      end

      # Given an Actor that responds to +uuid+, +finished?+ and +receive_message+,
      # mark this message as wanting to receive all messages that match +uuid+ until
      # the object is done receiving messages.
      def wait_for_persistent(receiver)
        @receivers[ receiver.uuid ] = StreamReceiver.new(receiver)
      end

      # Is there a future waiting for this response message?
      def waiting_for?(message)
        !@receivers[ message.uuid ].nil?
      end

      def received(message)
        if receiver = @receivers[ message.uuid ]
          receiver.receive(message)
          @receivers[ message.uuid ] = nil if receiver.finished?
        end
      end

      protected

      class OneShotReceiver
        attr_reader :future

        def initialize(message)
          @message = message
          @future = Celluloid::Future.new
        end

        # Internal to Celluloid::Future, using #signal ends up in a Result object
        # in which calling #value then calls #value on the saved data which in our
        # case is Message. We just want the Message so wrap up our messages in this
        # object to work around this oddity.
        #
        # https://github.com/celluloid/celluloid/blob/master/lib/celluloid/future.rb#L89
        FutureResultWrapper = Struct.new(:value)

        def receive(message)
          @future.signal(FutureResultWrapper.new(message))
        end

        def finished?
          true
        end
      end

      class StreamReceiver
        def initialize(receiver)
          @receiver = receiver
        end

        def receive(message)
          @receiver.async.receive_message(message)
        end

        def finished?
          @receiver.finished?
        end
      end

    end

  end
end
