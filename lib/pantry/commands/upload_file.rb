module Pantry
  module Commands

    # Base class for any command that needs to upload a single file where
    # that file is small enough for it's contents to be passed around in plain messages.
    # For larger files that shouldn't be pulled entirely into memory, please use
    # #send_file / #receive_file instead.
    #
    # This class is not used directly. Subclass to define the CLI command pattern
    # and the directory where the uploaded file will end up.
    class UploadFile < Pantry::Command

      def initialize(file_path = nil)
        @file_path = file_path
      end

      # Specify the directory this file should be written to
      # When applicable, +application+ is the application that should know about this file
      def upload_directory(application)
        raise "Must implement #upload_directory in subclass"
      end

      def prepare_message(filter, options)
        application = options['application']
        raise Pantry::MissingOption, "Required option APPLICATION is missing" unless application

        super.tap do |message|
          message << options
          message << File.basename(@file_path)
          message << File.read(@file_path)
        end
      end

      def perform(message)
        cmd_options = message.body[0]
        file_name   = message.body[1]
        file_body   = message.body[2]

        upload_dir = upload_directory(cmd_options)

        FileUtils.mkdir_p(upload_dir)
        File.open(upload_dir.join(file_name), "w+") do |file|
          file.write file_body
        end

        true
      end

    end

  end
end
