module Pantry
  module Commands

    # Edit the configuration of the requested Application.
    #
    # Application configuration is stored on the Server under
    # Pantry.root/applications/[app name]/config.yml and is where all
    # configuration lives for how Pantry manages this application.
    class EditApplication < Pantry::Command

      command "edit" do
        description "Edit an application's configuration with the text editor specified in $EDITOR.
          Requires an Application."
      end

      def prepare_message(options)
        @application = options[:application]
        raise Pantry::MissingOption, 'Missing required option "application"' unless @application

        # Let the EDITOR check run before we do any communication
        @editor = Pantry::FileEditor.new

        super.tap do |msg|
          msg << @application
        end
      end

      # Read or create a new config file for the given application
      # and return the contents of this config file, which will always be
      # a YAML document
      def perform(message)
        application = message.body[0]

        config_file = Pantry.root.join("applications", application, "config.yml")
        FileUtils.mkdir_p(File.dirname(config_file))

        if File.exists?(config_file)
          [File.read(config_file)]
        else
          [{"name" => application}.to_yaml]
        end
      end

      def receive_server_response(message)
        current_config = message.body[0]
        new_config     = @editor.edit(current_config, :yaml)

        if new_config != current_config
          send_request!(
            Pantry::Commands::UpdateApplication.new(
              @application, new_config
            ).to_message
          )
        end
      end

    end

  end
end
