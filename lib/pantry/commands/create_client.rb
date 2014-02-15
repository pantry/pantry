module Pantry
  module Commands

    class CreateClient < Pantry::Command
      command "client:create" do
        description "Generate a new public/private encryption keypair for a client."
      end

      # Ask the server to generate a new set of keys,
      # returning a hash that contains the required keys for a client to properly
      # conenct and authenticate to this server
      def perform(message)
        server.create_client
      end

      def receive_response(message)
        keys = message.body[0]
        Pantry.ui.say("New Client Credentials:")
        Pantry.ui.say(YAML.dump({
          "server_public_key" => keys[:server_public_key],
          "public_key" => keys[:public_key],
          "private_key" => keys[:private_key]
        }))
        super
      end

    end

  end
end
