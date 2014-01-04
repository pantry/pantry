module Pantry
  module Chef

    # Given a list of cookbooks and the Receivers waiting for them,
    # set up some senders to start sending the appropriate Cookbook files along.
    class SendCookbooks < Pantry::Command

      def self.command_type
        "Chef::SendCookbooks"
      end

      def perform(message)
        message.body.each do |(name, version, receiver_identity, file_uuid)|
          server.send_file(
            Pantry.root.join("chef", "cookbooks", name, "#{version}.tgz"),
            receiver_identity,
            file_uuid
          )
        end

        true
      end

    end

  end
end
