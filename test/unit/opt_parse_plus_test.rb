require 'unit/test_helper'

describe OptParsePlus do

  it "adds block and option support to optparse" do
    parser = OptParsePlus.new
    parser.add_options do
      option "-a", "--application APPLICATION", String, "An option"
    end

    command_line = %w(-a application_name)
    options      = parser.parse!(command_line)

    assert_equal "application_name", options['application']
    assert_equal "application_name", options[:application]
    assert_equal [], command_line
  end

  it "adds command support to optparse" do
    parser = OptParsePlus.new
    parser.add_command("one") do
      option "-a", "--application APPLICATION", String, "An option"
    end

    command_line = %w(one -a application_name)
    options      = parser.parse!(command_line)

    assert_equal "application_name", options['one']['application']
    assert_equal "application_name", options[:one][:application]
    assert_equal [], command_line
  end

  it "allows setting an explicit banner" do
    parser = OptParsePlus.new
    parser.banner "pantry [command]"

    help_text = parser.help
    assert_match /pantry \[command\]/, help_text
  end

  it "allows specifying a description" do
    parser = OptParsePlus.new
    parser.add_options do
      description "This is interesting yes!"
    end

    help_text = parser.help
    assert_match /This is interesting/, help_text
  end

  it "works with commands with no block" do
    parser = OptParsePlus.new
    parser.add_command("run")

    options = parser.parse!(%w(run))
    assert_equal "run", options.command_found
  end

  it "allows specifying argument usage in the command name" do
    parser = OptParsePlus.new
    parser.add_command("run COMMAND")

    command_line = %w(run Something)
    options = parser.parse!(command_line)

    assert_equal "run", options.command_found
    assert_equal %w(Something), command_line
  end

  it "gives the command options the arguments as per the description string (???)"

  it "processes arguments in order to support global and command options" do
    parser = OptParsePlus.new
    parser.add_options do
      option "-L", "--log-level LEVEL"
    end

    parser.add_command("run") do
      option "-c", "--command COMMAND"
    end

    command_line = %w(-L debug run --command DoThisNow)
    options      = parser.parse!(command_line)

    assert_equal "run", options.command_found
    assert_equal "debug", options['log-level']
    assert_equal "DoThisNow", options['run']['command']
  end

  it "groups commands together, sorting subcommands alphabetically" do
    parser = OptParsePlus.new
    parser.add_command("run") do
      group "Exercise"
    end

    parser.add_command("bike") do
      group "Exercise"
    end

    parser.add_command("sleep") do
      group "Lazy"
    end

    output, err = capture_io do
      parser.parse!(%w(--help))
    end

    # Group subheadings
    assert_match /Exercise commands/, output
    assert_match /Lazy commands/, output

    # Check alphabetical sort
    assert_match /bike.*run/m, output
  end

  it "adds a global help option" do
    parser = OptParsePlus.new

    options = nil
    output, err = capture_io do
      options = parser.parse!(%w(-h))
    end

    assert_match /Show this help message/, output
    assert options['help'], "Help flag was not set"
  end

  it "adds help option to each command configured" do
    parser = OptParsePlus.new
    parser.add_command("run")

    options = nil
    output, err = capture_io do
      options = parser.parse!(%w(run --help))
    end

    assert_match /Show this help message/, output
    assert options['help']
  end

  it "allows explicitly getting the help text" do
    parser = OptParsePlus.new
    help_text = parser.help

    assert_match /Show this help message/, help_text
  end

  it "includes all known commands in the top-level help text" do
    parser = OptParsePlus.new
    parser.add_command("run") do
      description "Run something"
    end

    parser.add_command("stop") do
      description "Stop something from running"
    end

    parser.add_command("stock ITEM") do
      description "Stock the item"
    end

    help_text = parser.help

    assert_match /run\s+Run something/, help_text
    assert_match /stop\s+Stop something/, help_text
    assert_match /stock\s+Stock the item/, help_text
  end

  it "only shows the first line of a command's description in top-level help" do
    parser = OptParsePlus.new
    parser.add_command("run") do
      description "Run something.
        Run fast.
        Don't run slow"
    end

    help_text = parser.help

    assert_match /Run something/, help_text
    assert_no_match /Run fast/, help_text
    assert_no_match /Don't run slow/, help_text
  end

  it "includes sub-command descriptions and banner strings in help text" do
    parser = OptParsePlus.new
    parser.add_command("display MESSAGE") do
      description "Show the given message"
      option "-c", "--cap", "Capitalize the message"
    end

    help_text, error = capture_io do
      parser.parse!(["display", "--help"])
    end

    assert_match /display \[options\] MESSAGE/, help_text
    assert_match /-c, --cap/, help_text
    assert_match /Capitalize the message/, help_text
    assert_match /Show the given message/, help_text
  end

  it "cleans up extra white space in full command descriptions" do
    parser = OptParsePlus.new
    parser.add_command("display MESSAGE") do
      description "Show the given message.
        Requires a MESSAGE to be passed in.
        and will Error out otherwise"
    end

    help_text, error = capture_io do
      parser.parse!(["display", "--help"])
    end

    assert_match /^Show the given message/, help_text
    assert_match /^Requires a MESSAGE/, help_text
    assert_match /^and will Error/, help_text
  end

end
