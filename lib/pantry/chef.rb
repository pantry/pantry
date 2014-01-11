require 'digest'
require 'fileutils'
require 'tempfile'

require 'pantry/chef/upload_cookbook'
require 'pantry/chef/list_cookbooks'
require 'pantry/chef/sync_cookbooks'
require 'pantry/chef/send_cookbooks'

require 'pantry/chef/upload_role'
require 'pantry/chef/sync_roles'
require 'pantry/chef/download_roles'

require 'pantry/chef/upload_environment'
require 'pantry/chef/sync_environments'
require 'pantry/chef/download_environments'

require 'pantry/chef/configure_chef'
require 'pantry/chef/run_chef_solo'
require 'pantry/chef/run'

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

Pantry.add_server_command(Pantry::Chef::UploadRole)
Pantry.add_server_command(Pantry::Chef::SyncRoles)
Pantry.add_server_command(Pantry::Chef::DownloadRoles)

Pantry.add_server_command(Pantry::Chef::UploadEnvironment)
Pantry.add_server_command(Pantry::Chef::SyncEnvironments)
Pantry.add_server_command(Pantry::Chef::DownloadEnvironments)

Pantry.add_client_command(Pantry::Chef::Run)
Pantry.add_client_command(Pantry::Chef::ConfigureChef)
Pantry.add_client_command(Pantry::Chef::SyncCookbooks)
Pantry.add_client_command(Pantry::Chef::RunChefSolo)
