module Pantry
  module Commands

    # Download all content inside of the given directory.
    #
    # This command expects simple directories with a small number of files that are
    # themselves small in size, as this command reads every file into memory and sends
    # that raw content back to the Client. If there are more substantial files to transfer
    # use #send_file and #receive_file instead.
    class DownloadDirectory < Pantry::Command

      def initialize(directory = nil)
        @directory = directory
      end

      def perform(message)
        directory = Pantry.root.join(message.body[0])

        Dir[directory.join("*")].map do |role|
          [File.basename(role), File.read(role)]
        end
      end

      def to_message
        super.tap do |message|
          message << @directory.to_s
        end
      end

    end

  end
end
