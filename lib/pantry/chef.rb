require 'digest'
require 'tempfile'

require 'pantry/chef/upload_cookbook'
require 'pantry/chef/run_chef_solo'

module Pantry
  module Chef

    class UnknownCookbook < Exception; end

    class MissingMetadata < Exception; end

  end
end


Pantry.add_server_command(Pantry::Chef::UploadCookbook)
Pantry.add_client_command(Pantry::Chef::RunChefSolo)

Pantry::CLI::COMMAND_MAP["chef:upload:cookbook"] = Pantry::Chef::UploadCookbook
Pantry::CLI::COMMAND_MAP["chef:solo"]            = Pantry::Chef::RunChefSolo
