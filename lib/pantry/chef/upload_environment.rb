module Pantry
  module Chef

    # Upload a environment definition to the server
    class UploadEnvironment < Pantry::Commands::UploadFile

      command "chef:environment:upload ENV_FILE" do
        description "Upload the file at ENV_FILE as a Chef Environment. Requires an Application."
        group "Chef"
      end

      def required_options
        %i(application)
      end

      def upload_directory(options)
        Pantry.root.join("applications", options[:application], "chef", "environments")
      end

      def prepare_message(options)
        Pantry.ui.say("Uploading environment #{File.basename(file_to_upload)}...")
        super
      end

    end

  end
end
