require 'unit/test_helper'

describe Pantry::Chef::ConfigureChef do

  fake_fs!

  it "has a custom type" do
    assert_equal "Chef::Configure", Pantry::Chef::ConfigureChef.command_type
  end

  it "creates expected directory structure for chef file storage" do
    command = Pantry::Chef::ConfigureChef.new
    command.perform(Pantry::Message.new)

    assert File.directory?(Pantry.root.join("chef", "cache")),
      "Did not create the chef file cache directory"

    assert File.directory?(Pantry.root.join("chef", "cookbooks")),
      "Did not create the chef cookbooks directory"
  end

  it "writes out chef/solo.rb pointing chef to the right locations" do
    command = Pantry::Chef::ConfigureChef.new
    command.perform(Pantry::Message.new)

    solo_rb = Pantry.root.join("etc", "chef", "solo.rb")
    assert File.exists?(solo_rb), "Did not write out a solo.rb file"

    solo_contents = File.read(solo_rb)

    assert_match %|cookbook_path "#{Pantry.root.join("chef", "cookbooks")}|,
      solo_contents
    assert_match %|file_cache_path "#{Pantry.root.join("chef", "cache")}|,
      solo_contents
  end

  it "writes out the current environment of the Client if one exists" do
    client = Pantry::Client.new(environment: "staging")

    command = Pantry::Chef::ConfigureChef.new
    command.server_or_client = client
    command.perform(Pantry::Message.new)

    solo_rb = Pantry.root.join("etc/chef/solo.rb")
    solo_contents = File.read(solo_rb)

    assert_match %|environment "staging"|, solo_contents
  end

end