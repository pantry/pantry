module Pantry
  module Chef

    # Client syncs up it's local list of Chef Roles with what the Server
    # says the Client should have.
    class SyncRoles < Pantry::Command

      command "chef:roles:sync" do
        description "Update Clients with the roles they should know about."
      end

      def self.message_type
        "Chef::SyncRoles"
      end

      def perform(message)
        roles = send_request!(Pantry::Chef::DownloadRoles.new.to_message)

        roles_dir = Pantry.root.join("chef", "roles")
        FileUtils.mkdir_p(roles_dir)

        roles.body.each do |(role_name, role_contents)|
          File.open(roles_dir.join(role_name), "w+") do |file|
            file.write(role_contents)
          end
        end

        true
      end

    end
  end
end

