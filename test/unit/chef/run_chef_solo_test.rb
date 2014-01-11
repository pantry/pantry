require 'unit/test_helper'

describe Pantry::Chef::RunChefSolo do

  it "executes the chef-solo command, returning outputs" do
    config_file = Pantry.root.join(*%w(etc chef solo.rb))
    Open3.expects(:capture3).with("chef-solo --config #{config_file}").
      returns(["chef ran", "error", 0])

    command = Pantry::Chef::RunChefSolo.new
    stdout, stderr, status = command.perform(Pantry::Message.new)

    assert_equal "chef ran", stdout
    assert_equal "error", stderr
    assert_equal 0, status
  end

  it "returns error message if chef-solo not found on the system" do
    Open3.expects(:capture3).raises(Errno::ENOENT, "Can't find LOLZ")

    command = Pantry::Chef::RunChefSolo.new
    stdout, stderr, status = command.perform(Pantry::Message.new)

    assert_equal "", stdout
    assert_equal "No such file or directory - Can't find LOLZ", stderr
    assert_equal 1, status
  end

end
