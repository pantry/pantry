module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # The top-level set of CLI options and flags Pantry respects
    BASE_OPTIONS = proc {
      banner "Usage: #{$0} [options] [command [command options]]"
      option "-a", "--application APPLICATION", String, "Filter Clients by a specific APPLICATION"
      option "-e", "--environment ENVIRONMENT", String, "Filter Clients by a specific ENVIRONMENT"
      option "-r", "--roles ROLE1,ROLE2",       Array,  "Filter Clients by given ROLES"
      option "-v", "--verbose", "Verbose output (INFO)"
      option "-d", "--debug",   "Even more Verbose output (DEBUG)"
      option "-V", "--version", "Print out Pantry's version"
    }

    def initialize(command_line, **args)
      @progress_listener = args.delete(:progress_listener) || Pantry::CLIProgressListener.new
      @command_line      = command_line

      args[:identity] ||= ENV["USER"]
      super(**args)
    end

    def run
      super

      find_all_cli_commands
      options, arguments = parse_command_line(@command_line)
      if options && process_global_command_line_options(options)
        process_command(options, arguments)
      end
      terminate
    end

    def find_all_cli_commands
      @known_commands = {}
      Pantry.all_commands.each do |command_class|
        if command_class.command_name
          # Hmm duplicated from OptParsePlus
          base_command_name = command_class.command_name.split(/\s/).first
          @known_commands[base_command_name] = command_class
        end
      end
    end

    def parse_command_line(command_line)
      begin
        parser = OptParsePlus.new
        parser.add_options(&BASE_OPTIONS)

        @known_commands.each do |command_name, command_class|
          parser.add_command(command_name, &command_class.command_config)
        end

        options = parser.parse!(command_line)

        if options['help']
          # Help printed already
          return [nil, nil]
        end

        [options, command_line]
      rescue => ex
        puts ex, ""
        puts parser.help
        [nil, nil]
      end
    end

    def process_global_command_line_options(options)
      if options["verbose"]
        Pantry.config.log_level = :info
        Pantry.config.refresh
      end

      if options["debug"]
        Pantry.config.log_level = :debug
        Pantry.config.refresh
      end

      if options["version"]
        puts Pantry::VERSION
        terminate
        return false
      end

      true
    end

    def process_command(options, arguments)
      triggered_command = options.command_found
      if command_class = @known_commands[triggered_command]
        client_filter = Pantry::Communication::ClientFilter.new(
          application: options['application'],
          environment: options['environment'],
          roles:       options['roles']
        )

        command = command_class.new(*arguments)

        request(client_filter, command, options[triggered_command])
      else
        Pantry.logger.error("[CLI] I don't know the #{command.inspect} command")
      end
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    #
    # Returns a CLI::Response object that will eventually have the responses
    # from the Server and/or Clients.
    def request(filter, command, options)
      @command = command
      @command.server_or_client  = self
      @command.progress_listener = @progress_listener

      # We don't use send_request here because we don't want to deal with the
      # wait-list future system. This lets command objects handle responses
      # as they come back to the CLI as the command sees fit.
      # If the command isn't meant directly for the Server, the Server will always
      # respond first with the list of clients who will be executing the command
      # and responding with the results. See Pantry::Commands::Echo for an example of how
      # to work with this flow.
      message = @command.prepare_message(filter, options)
      message.requires_response!

      send_message(message)

      @command.progress_listener.wait_for_finish
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      if @command
        @command.receive_response(message)
      end
    end

  end

end
