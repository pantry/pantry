module Pantry
  module Chef

    # Upload a role definition to the server
    class UploadRole < Pantry::Commands::UploadFile

      command "chef:role:upload ROLE_FILE" do
        description "Upload the file at ROLE_FILE as a Chef Role. Requires an Application"
        group "Chef"
      end

      def required_options
        %i(application)
      end

      def upload_directory(options)
        Pantry.root.join("applications", options[:application], "chef", "roles")
      end

      def prepare_message(*args)
        Pantry.ui.say("Uploading role #{File.basename(file_to_upload)}...")
        super
      end

    end

  end
end
