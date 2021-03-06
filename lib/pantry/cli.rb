module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    def initialize(command_line, **args)
      @command_line = Pantry::CommandLine.new(command_line)

      args[:identity] ||= ENV["USER"]
      super(**args)
    end

    def run
      prepare_local_pantry_root

      options, arguments = @command_line.parse!
      if options && process_global_options(options)
        super
        perform(options, arguments)
      end

      terminate
    end

    def prepare_local_pantry_root
      if Pantry.config.root_dir.nil?
        # TODO Find a .pantry up the chain vs building one
        Pantry.config.root_dir = File.join(Dir.pwd, ".pantry")
        FileUtils.mkdir_p(Pantry.root)
      end
    end

    def process_global_options(options)
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
        copy_keys_file_into_pantry_root(curve_key_file)
      end

      if options["version"]
        Pantry.ui.say Pantry::VERSION
        terminate
        return false
      end

      true
    end

    # Given the parsed options and the arguments left over,
    # figure out what Command was requested, build up the appropriate structures
    # and start the communication process.
    def perform(options, arguments)
      command_info, command_options = @command_line.triggered_command

      if command_info
        client_filter = Pantry::Communication::ClientFilter.new(
          application: options['application'],
          environment: options['environment'],
          roles:       options['roles']
        )

        command = command_info[:class].new(*arguments)
        command_options = command_options.merge(options)

        request(client_filter, command, command_options)
      else
        $stderr.puts "I don't know the #{arguments.first} command"
      end
    end

    # Fire off the requested Command.
    def request(filter, command, options)
      @command = command
      @command.client = self

      # We don't use send_request here because we don't want to deal with the
      # wait-list future system. This lets command objects handle responses
      # as they come back to the CLI as the command sees fit.
      # If the command isn't meant directly for the Server, the Server will always
      # respond first with the list of clients who will be executing the command
      # and responding with the results. See Pantry::Commands::Echo for an example of how
      # to work with this flow.
      begin
        message = @command.prepare_message(options)
        message.to = filter.stream
        message.requires_response!

        send_message(message)

        @command.wait_for_finish

        copy_full_keys_back_to_curve_key_file
      rescue Exception => ex
        Pantry.ui.say("Error: #{ex.message}")
        Pantry.logger.debug(ex.backtrace.join("\n"))
      end
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      if @command
        @command.receive_response(message)
      end
    end

    protected

    #
    # For the sake of being a Client, the file mentioned in --curve-key-file is
    # copied into security/curve/client_keys.yml so that we don't have to do anything
    # special to turn on Curve encryption for the Client. We do this for every run to ensure
    # that if the keys or options change, the user isn't confused when the client is unable to
    # connect or auth.
    #
    # To facilitate the first-time-connect situation, where a new Pantry Server has been spun up
    # and the only known key is the server's public key, this will also copy the keys file back
    # up to the file named in --curve-key-file because it will fill that file with a set of
    # generated public and private keys.
    #

    def copy_keys_file_into_pantry_root(curve_key_file)
      @curve_key_file = curve_key_file
      FileUtils.mkdir_p(Pantry.root.join("security", "curve"))
      FileUtils.cp(
        Pantry.root.join(@curve_key_file),
        Pantry.root.join("security", "curve", "client_keys.yml")
      )
    end

    def copy_full_keys_back_to_curve_key_file
      return unless @curve_key_file
      FileUtils.cp(
        Pantry.root.join("security", "curve", "client_keys.yml"),
        Pantry.root.join(@curve_key_file)
      )
    end

  end

end
