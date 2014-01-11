module Pantry
  module Chef

    # List all roles known by the Server for the requesting Client,
    # including the contents of the roles as uploaded to the Server
    class DownloadRoles < Pantry::Command

      def self.message_type
        "Chef::DownloadRoles"
      end

      def perform(message)
        client = server.client_who_sent(message)
        application = client.application

        Dir[Pantry.root.join("applications", application, "chef", "roles", "*")].map do |role|
          [File.basename(role), File.read(role)]
        end
      end

    end

  end
end
