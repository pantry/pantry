module Pantry
  module Chef

    # List all environments known by the Server for the requesting Client,
    # including the contents of the environments as uploaded to the Server
    class DownloadEnvironments < Pantry::Command

      def self.message_type
        "Chef::DownloadEnvironments"
      end

      def perform(message)
        client = server.client_who_sent(message)
        application = client.application

        Dir[
          Pantry.root.join("applications", application, "chef", "environments", "*")
        ].map do |environment|
          [File.basename(environment), File.read(environment)]
        end
      end

    end

  end
end
