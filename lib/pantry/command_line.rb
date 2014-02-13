module Pantry

  class CommandLine

    # The top-level set of CLI options and flags Pantry respects
    BASE_OPTIONS = proc {
      banner "Usage: #{File.basename($0)} [options] [command [command options]]"
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

    def initialize(command_line)
      @command_line   = command_line
      @known_commands = {}

      @commands = find_all_cli_enabled_commands
    end

    # Parse the full command line. Returns a hash containing the options found
    # as well as what is still left on the command line.
    # If the command line is empty, will default to --help.
    #
    # Returns [nil, nil] if help was requested or there was a problem.
    def parse!
      @command_line = merge_command_line_with_defaults(@command_line)
      parser = build_parser(@commands)

      begin
        if @command_line.empty?
          @command_line << "--help"
        end

        @parsed_options = parser.parse!(@command_line)

        if @parsed_options['help']
          # Help printed already
          return [nil, nil]
        end

        [@parsed_options, @command_line]
      rescue => ex
        puts ex, ""
        puts parser.help
        [nil, nil]
      end
    end

    # Returns details of the command found during parsing.
    # Returns a hash with the keys +banner+ and +class+,
    # or returns nil if no matching command was found
    def triggered_command
      [
        @commands[@parsed_options.command_found],
        @parsed_options[@parsed_options.command_found]
      ]
    end

    protected

    def find_all_cli_enabled_commands
      commands = {}
      Pantry.all_commands.each do |command_class|
        if command_class.command_name
          # Hmm duplicated from OptParsePlus
          base_command_name = command_class.command_name.split(/\s/).first
          commands[base_command_name] = {
            banner: command_class.command_name,
            class:  command_class
          }
        end
      end

      commands
    end

    def merge_command_line_with_defaults(command_line)
      [read_defaults_file, command_line].flatten
    end

    def read_defaults_file
      dot_pantry_config = Pantry.root.join("config")

      if File.exist?(dot_pantry_config)
        # ARGV is an array of the command line seperated by white-space.
        # Make sure what we read from .pantry returns the same
        File.readlines(dot_pantry_config).map { |line|
          line.strip.split(/\s/)
        }.flatten
      else
        []
      end
    end

    def build_parser(cli_commands)
      parser = OptParsePlus.new
      parser.add_options(&BASE_OPTIONS)

      cli_commands.each do |base_command_name, command_info|
        parser.add_command(command_info[:banner], &command_info[:class].command_config)
      end

      parser
    end

  end

end
