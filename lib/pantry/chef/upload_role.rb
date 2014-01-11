module Pantry
  module Chef

    # Upload a role definition to the server
    class UploadRole < Pantry::Command

      command "chef:role:upload ROLE_FILE" do
        description "Upload the file at ROLE_FILE as a Chef Role. Requires an Application"
      end

      def self.message_type
        "Chef::UploadRole"
      end

      def initialize(role_path = nil)
        @role_path = role_path
      end

      def prepare_message(filter, options)
        application = options['application']
        raise Pantry::MissingOption, "Required option APPLICATION is missing" unless application

        super.tap do |message|
          message << application
          message << File.basename(@role_path)
          message << File.read(@role_path)
        end
      end

      def perform(message)
        application = message.body[0]
        role_name   = message.body[1]
        role_body   = message.body[2]

        roles_dir = Pantry.root.join("applications", application, "chef", "roles")
        FileUtils.mkdir_p(roles_dir)
        File.open(roles_dir.join(role_name), "w+") do |file|
          file.write role_body
        end

        true
      end

    end

  end
end
