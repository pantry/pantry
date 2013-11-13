require 'celluloid'
require 'celluloid/zmq'
require 'json'
require 'logger'
require 'securerandom'
require 'socket'
require 'open3'

require 'pantry/config'
require 'pantry/logger'

require 'pantry/command'
require 'pantry/command_handler'

require 'pantry/commands/echo'
require 'pantry/commands/execute_shell'
require 'pantry/commands/list_clients'
require 'pantry/commands/register_client'

require 'pantry/commands/run_chef_solo'

require 'pantry/communication'
require 'pantry/communication/server'
require 'pantry/communication/client'
require 'pantry/communication/client_filter'
require 'pantry/communication/message'
require 'pantry/communication/wait_list'

require 'pantry/communication/reading_socket'
require 'pantry/communication/writing_socket'
require 'pantry/communication/publish_socket'
require 'pantry/communication/subscribe_socket'
require 'pantry/communication/receive_socket'
require 'pantry/communication/send_socket'

require 'pantry/client_registry'

require 'pantry/client'
require 'pantry/server'
require 'pantry/cli'


module Pantry

  # Register a command object class for the commands system.
  # This will register the command object as handleable by both the Server and a Client.
  def add_command(command_class)
    add_client_command(command_class)
    add_server_command(command_class)
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

  def ensure_proper_command_class(command_class)
    unless command_class.is_a?(Class)
      raise Pantry::InvalidCommandError.new("Expected a Class, got an #{command_class.class}")
    end

    unless command_class.ancestors.include?(Pantry::Command)
      raise Pantry::InvalidCommandError.new("Expected a class that's a subclass of Pantry::Command")
    end
  end

  def check_for_duplicates(command_list, command_class_to_add)
    known_commands = command_list.map(&:command_type)
    if known_commands.include?(command_class_to_add.command_type)
      raise Pantry::DuplicateCommandError.new("Command with type #{command_class_to_add.command_type} already registered")
    end
  end

  class InvalidCommandError < Exception; end

  class DuplicateCommandError < Exception; end

  extend self
end


##
# Register our built-in commands
##
Pantry.add_command(Pantry::Commands::Echo)

Pantry.add_client_command(Pantry::Commands::ExecuteShell)

Pantry.add_server_command(Pantry::Commands::ListClients)
Pantry.add_server_command(Pantry::Commands::RegisterClient)

##
# Register Chef-base commands
##
Pantry.add_client_command(Pantry::Commands::RunChefSolo)
