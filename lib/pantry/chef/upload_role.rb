module Pantry
  module Chef

    # Upload a role definition to the server
    class UploadRole < Pantry::Command

      command "chef:role:upload ROLE_FILE" do
        description "Upload the file at ROLE_FILE as a Chef Role"
      end

      def initialize(role_path = nil)
        @role_path = role_path
      end

      def perform(message)
        role_name = message.body[0]
        role_body = message.body[1]

        FileUtils.mkdir_p(Pantry.root.join("chef", "roles"))
        File.open(Pantry.root.join("chef", "roles", role_name), "w+") do |file|
          file.write role_body
        end

        true
      end

      def to_message
        message = super
        message << File.basename(@role_path)
        message << File.read(@role_path)
        message
      end

    end

  end
end
