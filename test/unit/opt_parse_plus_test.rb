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
    assert_equal [], command_line
  end

  it "allows specifying a banner via description" do
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
    assert options['run']['help']
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

  it "includes sub-command descriptions and banner strings in help text"

  it "builds help banner from the full stack of commands and options"

end
