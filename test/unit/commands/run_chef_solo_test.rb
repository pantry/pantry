require 'unit/test_helper'

describe Pantry::Commands::RunChefSolo do

  it "has a custom type" do
    assert_equal "Chef::ChefSolo", Pantry::Commands::RunChefSolo.command_type
  end

  it "executes the chef-solo command, returning outputs" do
    Open3.expects(:capture3).with("chef-solo").returns(["chef ran", "error", 0])

    command = Pantry::Commands::RunChefSolo.new
    stdout, stderr, status = command.perform

    assert_equal "chef ran", stdout
    assert_equal "error", stderr
    assert_equal 0, status
  end

end
