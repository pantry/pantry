module Pantry
  module Chef

    # Upload a environment definition to the server
    class UploadEnvironment < Pantry::Command

      command "chef:environment:upload ENV_FILE" do
        description "Upload the file at ENV_FILE as a Chef Environment. Requires an Application."
      end

      def initialize(environment_path = nil)
        @environment_path = environment_path
      end

      def prepare_message(filter, options)
        application = options['application']
        raise Pantry::MissingOption, "Required option APPLICATION is missing" unless application

        super.tap do |message|
          message << application
          message << File.basename(@environment_path)
          message << File.read(@environment_path)
        end
      end

      def perform(message)
        application      = message.body[0]
        environment_name = message.body[1]
        environment_body = message.body[2]

        env_dir = Pantry.root.join("applications", application, "chef", "environments")
        FileUtils.mkdir_p(env_dir)
        File.open(env_dir.join(environment_name), "w+") do |file|
          file.write environment_body
        end

        true
      end

    end

  end
end
