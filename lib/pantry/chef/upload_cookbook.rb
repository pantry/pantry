require 'chef'

module Pantry
  module Chef

    # Given a cookbook, upload it to the server
    class UploadCookbook < Pantry::Command

      attr_reader :cookbook_tarball

      def initialize(*args)
      end

      # Multi-step prepratory step here:
      #
      # * Find the cookbook in question
      # * Figure out if it's a valid cookbook (do some checks Chef doesn't itself do)
      # * Tar up the cookbook
      # * Figure out size and a checksum
      # * Package all this information into the message to send to the server
      #
      def prepare_message(filter, arguments = [])
        cookbook_path = arguments.first
        cookbook_name = File.basename(cookbook_path)
        cookbooks_dir = File.dirname(cookbook_path)

        loader   = ::Chef::CookbookLoader.new([cookbooks_dir])
        cookbook = loader.load_cookbooks[cookbook_name]

        raise UnknownCookbook, "Unable to find cookbook at #{cookbook_path}" unless cookbook
        raise MissingMetadata, "No metadata.rb found for cookbook at #{cookbook_path}" unless File.exist?(File.join(cookbook_path, "metadata.rb"))

        tempfile = Tempfile.new(cookbook_name)
        @cookbook_tarball = "#{tempfile.path}.tgz"
        tempfile.unlink

        # TODO Handle if this fails?
        Dir.chdir(cookbooks_dir) do
          Open3.capture2("tar", "czf", @cookbook_tarball, cookbook_name)
        end

        message = super
        message[:cookbook_version]  = cookbook.version
        message[:cookbook_name]     = cookbook.metadata.name
        message[:cookbook_size]     = File.size(@cookbook_tarball)
        message[:cookbook_checksum] = Digest::SHA256.file(@cookbook_tarball).hexdigest
        message
      end

#      def prepare(filter, *arguments)
#        metadata = "#{cookbook_path}/metadata.rb"
#        raise "Metadata file not found for cookbook" unless File.exists?(metadata)
#
#        # Pull these from the metadata
#        # Put these values in the message metadata
#        cookbook_name    = "name"
#        cookbook_version = "1.0"
#
#        cookbook_bundle_path = tar_cookbook_files
#
#        timeout = 5
#
#        # Ask for a new upload
#        # This checks that the file we're about to upload is kosher
#        to_server = UploadCookbook::Server.new.to_message
#        to_server[:cookbook_name] = cookbook_name
#        to_server[:cookbook_version] = cookbook_version
#
#        # Size
#        # Checksum
#
#        server_response = client.send_request(to_server).value(timeout)
#
#        # Upload is go! Time to trigger our upload actor and let it sort things out
#        # for itself.
#        uploader = client.upload_file(cookbook_bundle_path, server_response.uuid)
#        uploader.join
#
#        # Done uploading!
#      end
#
#
#      def perform(message)
#        cookbook_name    = message[:cookbook_name]
#        cookbook_version = message[:cookbook_version]
#
#        cookbooks_base = File.join(Pantry.config.data_dir, "chef", "cookbooks")
#
#        cookbook_final_upload_path =
#          File.join(cookbooks_base, cookbook_name, "#{cookbook_version}.tar.gz")
#
#        if File.exists?(cookbook_final_upload_path)
#          [false, "Cookbook #{cookbook_name} already has a version #{cookbook_version}"]
#        else
#          @server.receive_file(cookbook_final_upload_path,
#                               message[:upload_size],
#                               message[:upload_checksum])
#          [true]
#        end
#      end
#
#      def self.from_message(message)
#
#      end
#

    end

  end
end
