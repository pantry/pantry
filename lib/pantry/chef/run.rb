module Pantry
  module Chef

    class Run < Pantry::MultiCommand

      command "chef:run" do
        description "Run Chef on Clients"
        group "Chef"
      end

      performs [
        ConfigureChef,
        SyncCookbooks,
        SyncRoles,
        SyncEnvironments,
        SyncDataBags,
        RunChefSolo
      ]

      def initialize
        @received = []
        @expected_clients  = []
      end

      def receive_response(message)
        if message.from_server?
          Pantry.ui.say("Running chef on #{message.body.length} client...")
          @expected_clients = message.body
        else
          @received << message
          Pantry.ui.say("Chef on #{message.from} finished")
          Pantry.ui.say(message.body[5][0])
          Pantry.ui.say("")
        end

        if !@expected_clients.empty? && @received.length >= @expected_clients.length
          super
        end
      end

    end

  end
end
