module Pantry
  module Commands

    # Ask the server to generate a new set of keys
    # Prints a yaml file that contains the required keys for a client to properly
    # conenct and authenticate to the server
    class CreateClient < Pantry::Command
      command "client:create" do
        description "Generate a new public/private encryption keypair for a client."
      end

      def perform(message)
        server.create_client
      end

      def receive_server_response(message)
        keys = message.body[0]
        Pantry.ui.say("New Client Credentials")
        Pantry.ui.say("Store this in the Client's Pantry.root/security/curve/client_keys.yml")
        Pantry.ui.say(YAML.dump({
          "server_public_key" => keys[:server_public_key],
          "public_key" => keys[:public_key],
          "private_key" => keys[:private_key]
        }))
      end

    end

  end
end
