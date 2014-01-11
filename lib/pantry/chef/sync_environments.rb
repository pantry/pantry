module Pantry
  module Chef

    # Client syncs up it's local list of Chef Environments with what the Server
    # says the Client should have.
    class SyncEnvironments < Pantry::Command

      command "chef:environments:sync" do
        description "Update Clients with the environments they should know about."
      end

      def perform(message)
        environments = send_request!(Pantry::Chef::DownloadEnvironments.new.to_message)

        environments_dir = Pantry.root.join("chef", "environments")
        FileUtils.mkdir_p(environments_dir)

        environments.body.each do |(environment_name, environment_contents)|
          File.open(environments_dir.join(environment_name), "w+") do |file|
            file.write(environment_contents)
          end
        end

        true
      end

    end
  end
end

