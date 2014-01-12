module Pantry
  module Chef

    # Client syncs up it's local list of Chef Environments with what the Server
    # says the Client should have.
    class SyncEnvironments < Pantry::Commands::SyncDirectory

      def server_directory(local_root)
        local_root.join("applications", client.application, "chef", "environments")
      end

      def client_directory(local_root)
        local_root.join("chef", "environments")
      end

    end
  end
end

