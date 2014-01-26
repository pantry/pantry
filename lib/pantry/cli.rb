module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # The top-level set of CLI options and flags Pantry respects
    BASE_OPTIONS = proc {
      banner "Usage: #{$0} [options] [command [command options]]"
      option "-h", "--host HOSTNAME", String, "Hostname of the Server to connect to"
      option "--curve-key-file FILE", String, "Name of the file in .pantry holding Curve keys.",
        "Specifying this option will turn on Curve encryption."

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
      results = nil

      prepare_local_pantry_root
      find_all_cli_commands
      full_command_line = merge_command_line_with_defaults(@command_line)
      options, arguments = parse_command_line(full_command_line)

      if options && process_global_command_line_options(options)
        super
        results = process_command(options, arguments)
      end

      terminate
      results
    end

    def prepare_local_pantry_root
      return if Pantry.config.ignore_dot_pantry
      Pantry.config.data_dir = File.join(Dir.pwd, ".pantry")
      FileUtils.mkdir_p(Pantry.root)
    end

    def find_all_cli_commands
      @known_commands = {}
      Pantry.all_commands.each do |command_class|
        if command_class.command_name
          # Hmm duplicated from OptParsePlus
          base_command_name = command_class.command_name.split(/\s/).first
          @known_commands[base_command_name] = {
            banner:  command_class.command_name,
            class: command_class
          }
        end
      end
    end

    def merge_command_line_with_defaults(base_command_line)
      return base_command_line if Pantry.config.ignore_dot_pantry

      full_command_line = base_command_line

      dot_pantry_config = File.join(Dir.pwd, ".pantry", "config")
      if File.exist?(dot_pantry_config)
        # ARGV is an array of the command line seperated by white-space.
        # Make sure what we read from .pantry returns the same
        defaults = File.readlines(dot_pantry_config).map { |line|
          line.strip.split(/\s/)
        }.flatten
        full_command_line = [defaults, base_command_line].flatten
      end

      full_command_line
    end

    def parse_command_line(command_line)
      begin
        parser = OptParsePlus.new
        parser.add_options(&BASE_OPTIONS)

        if command_line.empty?
          command_line << "--help"
        end

        @known_commands.each do |base_command_name, command_info|
          parser.add_command(command_info[:banner], &command_info[:class].command_config)
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

      if server_host = options["host"]
        Pantry.config.server_host = server_host
      end

      if curve_key_file = options["curve-key-file"]
        Pantry.config.security = "curve"
        FileUtils.mkdir_p(Pantry.root.join("security", "curve"))
        FileUtils.cp(
          Pantry.root.join(curve_key_file),
          Pantry.root.join("security", "curve", "client_keys.yml")
        )
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
      if command_info = @known_commands[triggered_command]
        client_filter = Pantry::Communication::ClientFilter.new(
          application: options['application'],
          environment: options['environment'],
          roles:       options['roles']
        )

        command = command_info[:class].new(*arguments)
        command_options = options[triggered_command].merge(options)

        request(client_filter, command, command_options)
      else
        $stderr.puts "I don't know the #{arguments.first} command"
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
