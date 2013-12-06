module Pantry
  module Commands
    class MultiResponseHandler

      SERVER_RESPONSE_TIMEOUT = 5 # seconds
      CLIENT_RESPONSE_TIMEOUT = 5 # seconds

      def initialize(server_future)
        @server_future = server_future
        @messages = []
      end

      def wait_for_response
        # TODO Change this to a Condition on next release of Celluloid
        @wait_on_messages = Celluloid::Future.new
        ensure_server_response
      end

      def messages
        ensure_all_messages_received
        @messages
      end

      FutureResultWrapper = Struct.new(:value)
      def receive_message(message)
        Pantry.logger.debug("[CLI] Received message #{message.inspect}")
        @messages << message

        if @server_response && @messages.length >= @server_response.body.length
          Pantry.logger.debug("[CLI] Received all expected messages")
          @wait_on_messages.signal(FutureResultWrapper.new("success"))
        end
      end

      protected

      def ensure_server_response
        begin
          @server_response = @server_future.value(SERVER_RESPONSE_TIMEOUT)
          Pantry.logger.debug("[CLI] Server Response #{@server_response.inspect}")
        rescue Celluloid::TimeoutError
          Pantry.logger.error("[CLI] Did not receive response from Server in time.")
        end
      end

      def ensure_all_messages_received
        begin
          @wait_on_messages.value(CLIENT_RESPONSE_TIMEOUT)
        rescue Celluloid::TimeoutError
          Pantry.logger.error("[CLI] Did not receive all expected messages.")
        end
      end
    end
  end
end
