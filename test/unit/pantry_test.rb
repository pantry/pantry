require 'unit/test_helper'

describe Pantry do

  class TestCommand < Pantry::Command
  end

  before do
    Pantry.client_commands.clear
    Pantry.server_commands.clear
  end

  describe "#add_client_command" do
    it "adds commands only for the client to handle" do
      Pantry.add_client_command(TestCommand)

      assert_equal [TestCommand], Pantry.client_commands
      assert_equal [], Pantry.server_commands
      assert_equal [TestCommand], Pantry.all_commands
    end

    it "errors if the given class is not a Pantry::Command" do
      assert_raises(Pantry::InvalidCommandError) do
        Pantry.add_client_command(Object)
      end
    end

    it "errors if was given an object that isn't a Class" do
      assert_raises(Pantry::InvalidCommandError) do
        Pantry.add_client_command(Object.new)
      end
    end

    it "warns if the given Command conflicts name-wise with an already registered command" do
      Pantry.add_client_command(TestCommand)

      assert_raises(Pantry::DuplicateCommandError) do
        Pantry.add_client_command(TestCommand)
      end
    end
  end

  describe "#add_server_command" do
    it "adds commands only for the server to handle" do
      Pantry.add_server_command(TestCommand)

      assert_equal [], Pantry.client_commands
      assert_equal [TestCommand], Pantry.server_commands
      assert_equal [TestCommand], Pantry.all_commands
    end

    it "errors if the given class is not a Pantry::Command" do
      assert_raises(Pantry::InvalidCommandError) do
        Pantry.add_server_command(Object)
      end
    end

    it "errors if was given an object that isn't a Class" do
      assert_raises(Pantry::InvalidCommandError) do
        Pantry.add_server_command(Object.new)
      end
    end

    it "warns if the given Command conflicts name-wise with an already registered command" do
      Pantry.add_server_command(TestCommand)

      assert_raises(Pantry::DuplicateCommandError) do
        Pantry.add_server_command(TestCommand)
      end
    end
  end

end
