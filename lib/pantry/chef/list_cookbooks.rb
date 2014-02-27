module Pantry
  module Chef

    # List all cookbooks known by the Server.
    # This message includes the size and checksum of the cookbooks's tarball as it's used
    # when sending cookbooks down to a Client.
    class ListCookbooks < Pantry::Command

      command "chef:cookbook:list" do
        description "List all known cookbooks on the server."
        group "Chef"
      end

      def perform(message)
        Dir[Pantry.root.join("chef", "cookbook-cache", "*")].map do |cookbook_path|
          [
            File.basename(cookbook_path, ".tgz"),
            File.size(cookbook_path),
            Pantry.file_checksum(cookbook_path)
          ]
        end
      end

      def receive_response(message)
        Pantry.ui.list(message.body.map(&:first).sort)
        super
      end

    end

  end
end
