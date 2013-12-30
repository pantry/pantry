require 'digest'
require 'fileutils'
require 'tempfile'

require 'pantry/chef/upload_cookbook'
require 'pantry/chef/run_chef_solo'
require 'pantry/chef/download_cookbooks'

require 'pantry/chef/configure_chef'

module Pantry
  module Chef

    class UnknownCookbook < Exception; end

    class MissingMetadata < Exception; end

    class UploadError < Exception; end

  end
end

Pantry.add_server_command(Pantry::Chef::UploadCookbook)
Pantry.add_server_command(Pantry::Chef::DownloadCookbooks)

Pantry.add_client_command(Pantry::Chef::RunChefSolo)
Pantry.add_client_command(Pantry::Chef::ConfigureChef)
