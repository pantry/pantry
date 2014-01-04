require 'digest'
require 'fileutils'
require 'tempfile'

require 'pantry/chef/upload_cookbook'
require 'pantry/chef/run_chef_solo'
require 'pantry/chef/list_cookbooks'
require 'pantry/chef/sync_cookbooks'
require 'pantry/chef/send_cookbooks'

require 'pantry/chef/configure_chef'

module Pantry
  module Chef

    class UnknownCookbook < Exception; end

    class MissingMetadata < Exception; end

    class UploadError < Exception; end

  end
end

Pantry.add_server_command(Pantry::Chef::UploadCookbook)
Pantry.add_server_command(Pantry::Chef::ListCookbooks)
Pantry.add_server_command(Pantry::Chef::SendCookbooks)

Pantry.add_client_command(Pantry::Chef::RunChefSolo)
Pantry.add_client_command(Pantry::Chef::ConfigureChef)
