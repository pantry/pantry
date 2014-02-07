module Pantry
  module Chef

    # Upload a data bag file to the server
    class UploadDataBag < Pantry::Commands::UploadFile

      command "chef:data_bag:upload DATA_BAG_FILE" do
        description "Upload the data bag DATA_BAG_FILE to the server.
                     By default the name of the parent directory is the type of data bag.
                     Pass in --type to explicitly set the type of data bag.
                     Requires an Application."

        option "-t", "--type DATA_BAG_TYPE",
          "Specify the type of data bag being uploaded.
           Defaults to the name of the parent directory of the data bag file."
      end

      def required_options
        %i(application)
      end

      def upload_directory(options)
        Pantry.root.join("applications", options[:application], "chef", "data_bags", options[:type])
      end

      def prepare_message(filter, options)
        options[:type] ||= File.basename(File.dirname(file_to_upload))
        Pantry.ui.say("Uploading data bag #{File.basename(file_to_upload)}...")
        super
      end

    end

  end
end
