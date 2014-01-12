module Pantry
  module Chef

    # Client syncs up it's local list of Chef Roles with what the Server
    # says the Client should have.
    class SyncRoles < Pantry::Commands::SyncDirectory

      def server_directory(local_root)
        local_root.join("applications", client.application, "chef", "roles")
      end

      def client_directory(local_root)
        local_root.join("chef", "roles")
      end

    end
  end
end

