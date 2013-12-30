module Pantry
  module Chef

    # Figure out which cookbooks the given Client is supposed to have, build
    # senders for each cookbook and send back the sender UUIDs so the Client can
    # download.
    #
    # NOTE: For the time being, just gives the list of every known cookbook, latest
    # uploaded version.
    class DownloadCookbooks < Pantry::Command

      def self.command_type
        "Chef::DownloadCookbooks"
      end

      def perform(message)
        Dir[Pantry.root.join("chef", "cookbooks", "*")].map do |cookbook_path|
          process_and_start_sending_cookbook_at(cookbook_path)
        end
      end

      protected

      def process_and_start_sending_cookbook_at(cookbook_path)
        versions = Dir.entries(cookbook_path).sort {|a, b| b <=> a }

        latest_version = File.join(cookbook_path, versions.first)
        file_size      = File.size(latest_version)
        file_digest    = Digest::SHA256.file(latest_version).hexdigest

        [
          File.basename(cookbook_path),
          server.send_file(latest_version),
          file_size,
          file_digest
        ]
      end

    end

  end
end
