module Pantry
  module Chef

    # Upload a environment definition to the server
    class UploadEnvironment < Pantry::Command

      command "chef:environment:upload ENV_FILE" do
        description "Upload the file at ENV_FILE as a Chef Environment"
      end

      def initialize(environment_path = nil)
        @environment_path = environment_path
      end

      def perform(message)
        environment_name = message.body[0]
        environment_body = message.body[1]

        FileUtils.mkdir_p(Pantry.root.join("chef", "environments"))
        File.open(Pantry.root.join("chef", "environments", environment_name), "w+") do |file|
          file.write environment_body
        end

        true
      end

      def to_message
        message = super
        message << File.basename(@environment_path)
        message << File.read(@environment_path)
        message
      end

    end

  end
end
