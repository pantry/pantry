require 'chef'

module Pantry
  module Chef

    # Given a cookbook, upload it to the server
    class UploadCookbook < Pantry::Command

      command "chef:cookbook:upload [options] COOKBOOK_DIR" do
        description "Upload a given cookbook to the server."
        option      "-f", "--force", "Overwrite a previously uploaded version of this cookbook"
      end

      attr_reader :cookbook_tarball

      def initialize(cookbook_path = nil)
        @cookbook_path = cookbook_path
      end

      # Multi-step prepratory step here:
      #
      # * Find the cookbook in question
      # * Figure out if it's a valid cookbook (do some checks Chef doesn't itself do)
      # * Tar up the cookbook
      # * Figure out size and a checksum
      # * Package all this information into the message to send to the server
      #
      def prepare_message(filter, options)
        cookbook_name = File.basename(@cookbook_path)
        cookbooks_dir = File.dirname(@cookbook_path)

        loader   = ::Chef::CookbookLoader.new([cookbooks_dir])
        cookbook = loader.load_cookbooks[cookbook_name]

        raise UnknownCookbook, "Unable to find cookbook at #{@cookbook_path}" unless cookbook
        raise MissingMetadata, "No metadata.rb found for cookbook at #{@cookbook_path}" unless File.exist?(File.join(@cookbook_path, "metadata.rb"))

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

      # Server receives request message for a new Cookbook Upload.
      # Checks that the upload is valid
      # Fires off an upload receiver and returns the UUID for the client to use
      def perform(message)
        cookbook_name     = message[:cookbook_name]
        cookbook_version  = message[:cookbook_version]
        cookbook_size     = message[:cookbook_size]
        cookbook_checksum = message[:cookbook_checksum]

        cookbook_home = File.join(Pantry.config.data_dir, "chef", "cookbooks", cookbook_name)
        FileUtils.mkdir_p(cookbook_home)

        version_path = File.join(cookbook_home, "#{cookbook_version}.tgz")

        if !message[:cookbook_force_upload] && File.exists?(version_path)
          [false, "Version #{cookbook_version} of cookbook #{cookbook_name} already exists"]
        else
          uploader_uuid = server.receive_file(version_path, cookbook_size, cookbook_checksum)
          [true, uploader_uuid]
        end
      end

      # CLI has received a response from the server, handle the response and set up
      # the file transfer.
      def receive_response(response_message)
        upload_allowed = response_message.body[0]

        Pantry.logger.debug("[Upload Cookbook] #{response_message.inspect}")

        if upload_allowed == "true"
          client.send_file(@cookbook_tarball, response_message.body[1], listener: progress_listener)
        else
          progress_listener.error(response_message.body[1])
          progress_listener.finished
        end
      end

    end

  end
end
