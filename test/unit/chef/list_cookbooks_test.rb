require 'unit/test_helper'

describe Pantry::Chef::ListCookbooks do

  describe "#perform" do
    fake_fs!

    it "returns the list of cookbooks and latest version known" do
      cookbooks = [
        Pantry.root.join("chef", "cookbook-cache", "mini.tgz"),
        Pantry.root.join("chef", "cookbook-cache", "ruby.tgz"),
        Pantry.root.join("chef", "cookbook-cache", "pantry.tgz")
      ]

      cookbooks.each do|c|
        FileUtils.mkdir_p(File.dirname(c))
        FileUtils.touch(c)
      end

      Digest::SHA256.stubs(:file).returns(stub(:hexdigest => "deadbeef"))

      command = Pantry::Chef::ListCookbooks.new
      cookbook_list = command.perform(Pantry::Message.new)

      assert_equal [
        ["mini",   0, "deadbeef"],
        ["pantry", 0, "deadbeef"],
        ["ruby",   0, "deadbeef"]
      ], cookbook_list
    end
  end

  describe "#receive_response" do
    mock_ui!

    it "displays the list alphabetical order" do
      message = Pantry::Message.new
      message << ["pantry", 0, "deadbeef"]
      message << ["ruby", 0, "deadbeef"]
      message << ["mini", 0, "deadbeef"]

      command = Pantry::Chef::ListCookbooks.new
      command.receive_response(message)

      assert_equal "mini\npantry\nruby\n", stdout
    end
  end

end
