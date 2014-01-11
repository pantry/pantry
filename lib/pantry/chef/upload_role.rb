module Pantry
  module Chef

    # Upload a role definition to the server
    class UploadRole < Pantry::Commands::UploadFile

      command "chef:role:upload ROLE_FILE" do
        description "Upload the file at ROLE_FILE as a Chef Role. Requires an Application"
      end

      def upload_directory(application)
        Pantry.root.join("applications", application, "chef", "roles")
      end

    end

  end
end
