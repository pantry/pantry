require 'optparse'

class OptParsePlus

  attr_reader :options, :summary

  class OptionsFound < Hash
    attr_accessor :command_found
  end

  def initialize
    @parser = OptionParser.new
    @options = OptionsFound.new
    @commands = {}

    add_default_help
  end

  def add_options(&block)
    instance_exec(&block)
  end

  def add_command(command_name, &block)
    command_parser = OptParsePlus.new
    command_parser.add_options(&block) if block_given?
    @commands[base_command_name(command_name.to_s)] = command_parser
  end

  def option(*arguments)
    argument_name = parse_argument_name(arguments)
    @parser.on(*arguments) do |arg|
      @options[argument_name] = arg
    end
  end

  def description(message)
    @summary = message
    @parser.separator("")
    @parser.separator(message)
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
    help_parts = []
    help_parts << @parser.to_s

    if @commands.any?
      help_parts << ["Known Commands", ""]
      @commands.each do |command_name, parser|
        help_parts << "#{command_name} \t #{parser.summary}"
      end
      help_parts << ""
      help_parts << ""
    end

    help_parts.flatten.join("\n")
  end

  protected

  def add_default_help
    @parser.on_tail('-h', '--help', 'Show this help message') do
      puts help
      @options['help'] = true
    end
  end

  def base_command_name(command_string)
    command_string.split(/\s/).first
  end

  def parse_argument_name(arguments)
    full_name_arg = arguments.select {|a| a =~ /\A--/ }.first
    full_name_arg.split(/\s/).first.gsub("--", "")
  end

end
