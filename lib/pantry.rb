require 'celluloid'
require 'celluloid/zmq'
require 'json'
require 'logger'
require 'pathname'
require 'securerandom'
require 'socket'
require 'syslog/logger'
require 'open3'
require 'yaml'

require 'opt_parse_plus'
require 'celluloid_zmq_patches'

require 'pantry/version'
require 'pantry/ui'
require 'pantry/config'
require 'pantry/logger'
require 'pantry/message'
require 'pantry/command_line'
require 'pantry/file_editor'

require 'pantry/command'
require 'pantry/multi_command'
require 'pantry/command_handler'

require 'pantry/commands/echo'
require 'pantry/commands/edit_application'
require 'pantry/commands/update_application'
require 'pantry/commands/list_clients'
require 'pantry/commands/register_client'
require 'pantry/commands/upload_file'
require 'pantry/commands/sync_directory'
require 'pantry/commands/download_directory'

require 'pantry/communication'
require 'pantry/communication/serialize_message'
require 'pantry/communication/server'
require 'pantry/communication/client'
require 'pantry/communication/client_filter'
require 'pantry/communication/wait_list'

require 'pantry/communication/security/null_security'
require 'pantry/communication/security/curve_security'
require 'pantry/communication/security/curve_key_store'
require 'pantry/communication/security'

require 'pantry/communication/reading_socket'
require 'pantry/communication/writing_socket'
require 'pantry/communication/publish_socket'
require 'pantry/communication/subscribe_socket'
require 'pantry/communication/receive_socket'
require 'pantry/communication/send_socket'

require 'pantry/communication/file_service'
require 'pantry/communication/file_service/file_progress'
require 'pantry/communication/file_service/receive_file'
require 'pantry/communication/file_service/send_file'

require 'pantry/client_info'
require 'pantry/client_registry'

require 'pantry/client'
require 'pantry/server'
require 'pantry/cli'

module Pantry

  # Default identity of a Server, so as to help differentiate where
  # messages are coming from.
  SERVER_IDENTITY = ""

  ##
  # Various exceptions Pantry can raise
  ##

  # A command is expecting a certain option
  class MissingOption < Exception; end

  # Thrown when trying to add a non Pantry::Command class as a Pantry command
  class InvalidCommandError < Exception; end

  # Thrown when trying to add a Command that has the same message_type
  # as a Command already registered
  class DuplicateCommandError < Exception; end

  # The root of all stored Pantry data for this Server/Client
  # Uses Pantry.config.data_dir
  def root(config = Pantry.config)
    Pathname.new(config.data_dir)
  end

  # Register a command object class to be handled only by Clients
  def add_client_command(command_class)
    ensure_proper_command_class(command_class)
    check_for_duplicates(client_commands, command_class)

    client_commands << command_class
  end

  # Register a command object class to be handled only by the Server
  def add_server_command(command_class)
    ensure_proper_command_class(command_class)
    check_for_duplicates(server_commands, command_class)

    server_commands << command_class
  end

  # Return the list of known Client command classes
  def client_commands
    @client_commands ||= []
  end

  # Return the list of known Server command classes
  def server_commands
    @server_commands ||= []
  end

  # Return all known commands
  def all_commands
    [client_commands, server_commands].flatten
  end

  def ensure_proper_command_class(command_class)
    unless command_class.is_a?(Class)
      raise Pantry::InvalidCommandError.new("Expected a Class, got an #{command_class.class}")
    end

    unless command_class.ancestors.include?(Pantry::Command)
      raise Pantry::InvalidCommandError.new("Expected a class that's a subclass of Pantry::Command")
    end
  end

  def check_for_duplicates(command_list, command_class_to_add)
    known_commands = command_list.map(&:message_type)
    if known_commands.include?(command_class_to_add.message_type)
      raise Pantry::DuplicateCommandError.new("Command with type #{command_class_to_add.message_type} already registered")
    end
  end

  extend self
end

Celluloid.exception_handler do |exception|
  Pantry.logger.error("Exception thrown: #{exception.inspect}")
end

####################
# Command Registry #
####################

## Client Commands

Pantry.add_client_command(Pantry::Commands::Echo)

## Server Commands

Pantry.add_server_command(Pantry::Commands::EditApplication)
Pantry.add_server_command(Pantry::Commands::UpdateApplication)
Pantry.add_server_command(Pantry::Commands::ListClients)
Pantry.add_server_command(Pantry::Commands::RegisterClient)
Pantry.add_server_command(Pantry::Commands::DownloadDirectory)

# Chef Handling Commands and Code #
require 'pantry/chef'
