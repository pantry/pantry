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

      attr_reader :file_to_upload

      def initialize(file_to_upload = nil)
        @file_to_upload = file_to_upload
      end

      # Specify the directory this file should be written to
      # When applicable, +application+ is the application that should know about this file
      def upload_directory(application)
        raise "Must implement #upload_directory in subclass"
      end

      # Specify any required options for this Command by long-name
      # For example, to require the base APPLICATION option, return %i(application)
      # Does not matter if the list is of strings or symbols.
      def required_options
        []
      end

      def prepare_message(filter, options)
        required_options.each do |required|
          unless options[required]
            raise Pantry::MissingOption, "Required option #{required} is missing"
          end
        end

        super.tap do |message|
          message << options
          message << File.basename(@file_to_upload)
          message << File.read(@file_to_upload)
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
