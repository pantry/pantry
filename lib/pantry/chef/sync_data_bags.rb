module Pantry
  module Chef

    # Client syncs up it's local list of data bags with what the Server
    # says the Client should have.
    class SyncDataBags < Pantry::Commands::SyncDirectory

      def server_directory(local_root)
        local_root.join("applications", client.application, "chef", "data_bags")
      end

      def client_directory(local_root)
        local_root.join("chef", "data_bags")
      end

    end
  end
end

