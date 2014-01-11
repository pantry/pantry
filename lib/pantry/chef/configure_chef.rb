module Pantry
  module Chef

    class ConfigureChef < Pantry::Command

      command "chef:configure" do
        description "Configure the Client(s) for running Chef"
      end

      def perform(message)
        @base_chef_dir = Pantry.root.join("chef")
        @etc_dir       = Pantry.root.join("etc", "chef")
        create_required_directories
        write_solo_rb
        # TODO: Error handling response message?
        true
      end

      protected

      def create_required_directories
        FileUtils.mkdir_p(@base_chef_dir.join("cache"))
        FileUtils.mkdir_p(@base_chef_dir.join("cookbooks"))
        FileUtils.mkdir_p(@base_chef_dir.join("environments"))
        FileUtils.mkdir_p(@etc_dir)
      end

      # NOTE: Writes out the file every time this command is run.
      def write_solo_rb
        contents = []
        contents << %|file_cache_path "#{@base_chef_dir.join("cache")}"|
        contents << %|cookbook_path "#{@base_chef_dir.join("cookbooks")}"|

        if client && client.environment
          contents << %|environment "#{client.environment}"|
        end

        File.open(@etc_dir.join("solo.rb"), "w+") do |file|
          file.write(contents.join("\n"))
        end
      end

    end

  end
end
