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
        Dir[Pantry.root.join("chef", "cookbook-cache", "*")].map do |cookbook_path|
          build_cookbook_info(cookbook_path)
        end
      end

      protected

      def build_cookbook_info(cookbook_path)
        file_size      = File.size(cookbook_path)
        file_digest    = Digest::SHA256.file(cookbook_path).hexdigest

        [
          File.basename(cookbook_path, ".tgz"),
          "1.0.0",
          file_size,
          file_digest
        ]
      end

    end

  end
end
