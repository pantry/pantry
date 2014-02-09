require 'optparse'

class OptParsePlus

  attr_reader :options, :summary

  class OptionsFound < Hash
    attr_accessor :command_found

    # Let these options be queried by a string key or symbol
    # key equally.
    def [](key)
      super ||
        (key.is_a?(Symbol) && super(key.to_s)) ||
        (key.is_a?(String) && super(key.to_sym))
    end
  end

  def initialize(parent = nil)
    @parent = parent || self
    @parser = OptionParser.new
    @options = OptionsFound.new
    @commands = {}
    @summary = ""

    add_default_help
  end

  def add_options(&block)
    instance_exec(&block)
  end

  def add_command(command_name, &block)
    command_parser = OptParsePlus.new(self)

    base_command = base_command_name(command_name.to_s)
    rest = command_name.gsub(base_command, '')

    command_parser.banner "Usage: #$0 #{base_command} [options]#{rest}"
    command_parser.add_options(&block) if block_given?
    @commands[base_command] = command_parser
  end

  def option(*arguments)
    argument_name = parse_argument_name(arguments)
    @parser.on(*arguments) do |arg|
      @options[argument_name] = arg
    end
  end

  def banner(message)
    @parser.banner = message
  end

  def group(group_name = nil)
    if group_name
      @group = group_name
    else
      @group
    end
  end

  def description(message)
    @summary = message
    @parser.separator("")
    @parser.separator(message)
    @parser.separator("")
  end

  def set(key, value)
    @options[key] = value
  end

  def parse!(command_line)
    @parser.order!(command_line)
    final = @options

    next_token = command_line.first

    if command_parser = @commands[next_token]
      command_line.shift
      command_parser.parse!(command_line)

      final.command_found = next_token
      final.merge!({
        next_token => command_parser.options
      })
    end

    final
  end

  def help
    help_parts   = []
    help_parts << @parser.to_s

    if @commands.any?
      help_parts << ["Known Commands", ""]
      command_list = group_and_sort_command_help

      command_list.each do |cmd_line|
        help_parts << cmd_line
      end

      help_parts << ""
    end

    help_parts << ""
    help_parts.flatten.join("\n")
  end

  protected

  def add_default_help
    @parser.on_tail('-h', '--help', 'Show this help message') do
      puts help
      @parent.set('help', true)
    end
  end

  def base_command_name(command_string)
    command_string.split(/\s/).first
  end

  def parse_argument_name(arguments)
    full_name_arg = arguments.select {|a| a =~ /\A--/ }.first
    full_name_arg.split(/\s/).first.gsub("--", "")
  end

  def group_and_sort_command_help
    grouped_commands = Hash.new {|hash, key| hash[key] = []}

    @commands.each do |command_name, parser|
      grouped_commands[parser.group] << [command_name, parser]
    end

    command_list = []
    sorted_group_names = grouped_commands.keys.sort {|a, b| a.to_s <=> b.to_s }
    sorted_group_names.each do |group_name|
      command_list << build_help_for_command_group(group_name, grouped_commands[group_name])
    end

    command_list.flatten(1)
  end

  def build_help_for_command_group(group_name, group_commands)
    command_list = []

    if group_name
      command_list << nil
      command_list << "#{group_name} commands"
      command_list << nil
    end

    command_list + generate_short_help_for_commands(group_commands)
  end

  def generate_short_help_for_commands(group_commands)
    longest_command_length = 0
    group_commands.each do |(command_name, _)|
      longest_command_length = command_name.length if command_name.length > longest_command_length
    end
    # Give ourselves a small buffer between command and summary
    longest_command_length += 3

    sorted_group_commands = group_commands.sort {|a, b| a[0] <=> b[0]}
    sorted_group_commands.map do |(command_name, parser)|
      sprintf(
        "%-#{longest_command_length}s %s",
        command_name,
        first_line_of_summary(parser)
      )
    end
  end

  def first_line_of_summary(parser)
    parser.summary.split("\n").first
  end

end
