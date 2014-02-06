require 'unit/test_helper'

describe Pantry::Chef::ConfigureChef do

  fake_fs!

  it "creates expected directory structure for chef file storage" do
    command = Pantry::Chef::ConfigureChef.new
    command.perform(Pantry::Message.new)

    %w(cache cookbooks environments).each do |dir|
      assert File.directory?(Pantry.root.join("chef", dir)),
        "Did not create the chef #{dir} directory"
    end
  end

  it "writes out chef/solo.rb pointing chef to the right locations" do
    command = Pantry::Chef::ConfigureChef.new
    command.perform(Pantry::Message.new)

    solo_rb = Pantry.root.join("etc", "chef", "solo.rb")
    assert File.exists?(solo_rb), "Did not write out a solo.rb file"

    solo_contents = File.read(solo_rb)

    assert_match %r|cookbook_path\s*"#{Pantry.root.join("chef", "cookbooks")}|,
      solo_contents
    assert_match %r|file_cache_path\s*"#{Pantry.root.join("chef", "cache")}|,
      solo_contents
    assert_match %r|role_path\s*"#{Pantry.root.join("chef", "roles")}|,
      solo_contents
    assert_match %r|environment_path\s*"#{Pantry.root.join("chef", "environments")}|,
      solo_contents
    assert_match %r|json_attribs\s*"#{Pantry.root.join("etc", "chef", "node.json")}"|,
      solo_contents
  end

  it "writes out the node.json file with run list based on client roles" do
    client = Pantry::Client.new(roles: %w(app db))

    command = Pantry::Chef::ConfigureChef.new
    command.client = client
    command.perform(Pantry::Message.new)

    node_json = File.read(Pantry.root.join("etc", "chef", "node.json"))

    assert_match "role[app]", node_json
    assert_match "role[db]", node_json
  end

  it "writes out the current environment of the Client if one exists" do
    client = Pantry::Client.new(environment: "staging")

    command = Pantry::Chef::ConfigureChef.new
    command.client = client
    command.perform(Pantry::Message.new)

    solo_rb = Pantry.root.join("etc/chef/solo.rb")
    solo_contents = File.read(solo_rb)

    assert_match %|environment "staging"|, solo_contents
  end

end
