module Pantry
  module Chef

    # List all cookbooks known by the Server, and include the latest
    # version of said cookbook, as well as file size information for setting
    # up a file transfer.
    class ListCookbooks < Pantry::Command

      command "chef:cookbooks:list" do
        description "List all known cookbooks on the server"
      end

      def perform(message)
        Dir[Pantry.root.join("chef", "cookbooks", "*")].map do |cookbook_path|
          build_cookbook_info(cookbook_path)
        end
      end

      protected

      def build_cookbook_info(cookbook_path)
        versions = Dir.entries(cookbook_path).sort {|a, b| b <=> a }

        latest_version = File.join(cookbook_path, versions.first)
        file_size      = File.size(latest_version)
        file_digest    = Digest::SHA256.file(latest_version).hexdigest

        [
          File.basename(cookbook_path),
          File.basename(latest_version, File.extname(latest_version)),
          file_size,
          file_digest
        ]
      end

    end

  end
end
