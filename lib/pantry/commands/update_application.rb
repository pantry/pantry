module Pantry
  module Commands

    # Upload and save new configuration for an Application
    #
    # See EditApplication for more information
    class UpdateApplication < Pantry::Command

      def initialize(application_name = nil, config_body = nil)
        @application_name = application_name
        @config_body      = config_body
      end

      def to_message
        super.tap do |msg|
          msg << @application_name
          msg << @config_body
        end
      end

      def perform(message)
        application_name = message.body[0]
        config_body      = message.body[1]

        app_config_file = Pantry.root.join("applications", application_name, "config.yml")
        FileUtils.mkdir_p(File.dirname(app_config_file))

        begin
          Psych.parse(config_body, "config.yml")
        rescue => ex
          # Invalid YAML, don't save!
          return [false, ex.message]
        end

        File.open(app_config_file, "w+") do |file|
          file.write(config_body)
        end

        true
      end

    end

  end
end
