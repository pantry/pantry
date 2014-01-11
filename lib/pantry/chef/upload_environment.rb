module Pantry
  module Chef

    # Upload a environment definition to the server
    class UploadEnvironment < Pantry::Commands::UploadFile

      command "chef:environment:upload ENV_FILE" do
        description "Upload the file at ENV_FILE as a Chef Environment. Requires an Application."
      end

      def upload_directory(application)
        Pantry.root.join("applications", application, "chef", "environments")
      end

    end

  end
end
