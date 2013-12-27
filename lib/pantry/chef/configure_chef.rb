module Pantry
  module Chef

    class ConfigureChef < Pantry::Command

      command "chef:configure" do
        description "Configure the Client(s) for running Chef"
      end

      def self.command_type
        "Chef::Configure"
      end

      def perform(message)
        unless File.exists?("/etc/chef/solo.rb")
          @base_chef_dir = File.join(Pantry.config.data_dir, "chef")
          create_required_directories
          write_solo_rb
        end
      end

      protected

      def create_required_directories
        FileUtils.mkdir_p(File.join(@base_chef_dir, "cache"))
        FileUtils.mkdir_p(File.join(@base_chef_dir, "cookbooks"))
        FileUtils.mkdir_p("/etc/chef")
      end

      def write_solo_rb
        contents = []
        contents << %|file_cache_path "#{File.join(@base_chef_dir, "cache")}"|
        contents << %|cookbook_path "#{File.join(@base_chef_dir, "cookbooks")}"|

        if client && client.environment
          contents << %|environment "#{client.environment}"|
        end

        File.open("/etc/chef/solo.rb", "w+") do |file|
          file.write(contents.join("\n"))
        end
      end

    end

  end
end
