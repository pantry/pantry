module Pantry
  module Commands

    # Base class for any Command that needs to sync a set of files in a directory
    # from the Server down to the Client.
    #
    # Subclasses need to define where on the server the files live and where on
    # the client the files will be written to. Both #server_directory and #client_directory
    # are executed on the Client so #client is accessible for added information.
    #
    # This command expects simple directories with a small number of files that are
    # themselves small in size, as this command reads every file into memory and sends
    # that raw content back to the Client. If there are more substantial files to transfer
    # use #send_file and #receive_file instead.
    class SyncDirectory < Pantry::Command

      def server_directory(local_root)
        raise "Specify the read directory on the server"
      end

      def client_directory(local_root)
        raise "Specify the write directory on the client"
      end

      def perform(message)
        dir_contents = send_request!(
          Pantry::Commands::DownloadDirectory.new(
            server_directory(Pathname.new(""))
          ).to_message
        )

        write_to = client_directory(Pantry.root)
        FileUtils.mkdir_p(write_to)

        dir_contents.body.each do |(file_name, file_contents)|
          file_path = write_to.join(file_name).cleanpath
          FileUtils.mkdir_p(File.dirname(file_path))

          File.open(file_path, "w+") do |file|
            file.write(file_contents)
          end
        end

        true
      end

    end

  end
end
