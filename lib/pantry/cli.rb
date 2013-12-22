module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # The top-level set of CLI options and flags Pantry respects
    BASE_OPTIONS = proc {
      on :a, :application=, "Filter Clients by a specific Application"
      on :e, :environment=, "Filter Clients by a specific Environment"
      on :r, :roles=, "Filter Clients by given Roles [ROLE1,ROLE2,...]", as: Array, delimiter: ','
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
      build_all_command_options
      process_command
      terminate
    end

    def find_all_cli_commands
      @known_commands = {}
      Pantry.all_commands.each do |command_class|
        if command_class.command_name
          @known_commands[command_class.command_name] = command_class
        end
      end
    end

    def build_all_command_options
      command_list = @known_commands

      @command_options = proc {
        instance_exec(&BASE_OPTIONS)

        command_list.each do |name, command_class|
          command name, &(command_class.command_config || proc {})
        end
      }
    end

    def process_command
      options, rest_of_command_line = parse_command_line

      if options.nil?
        # Errored out =/
        return
      end

      if options[:help]
        # Printing already done by Slop itself
        terminate
        return
      end

      if command_class = @known_commands[options.triggered_commands.first]
        client_filter = Pantry::Communication::ClientFilter.new(
          application: options[:application],
          environment: options[:environment],
          roles:       options[:roles]
        )

        command = command_class.new(*rest_of_command_line)

        request(client_filter, command, options)
      else
        Pantry.logger.error("[CLI] I don't know the #{command.inspect} command")
      end
    end

    def parse_command_line
      begin
        slop = Slop.parse!(
          @command_line,
          help:              true,
          multiple_switches: false,
          strict:            true,
          ignore_case:       true,
          &@command_options
        )
        [slop, @command_line]
      rescue Slop::InvalidOptionError, Slop::MissingArgumentError => ex
        puts ex, ""
        puts Slop.new(&@command_options)
        terminate
        [nil, nil]
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
