require 'unit/test_helper'

describe Pantry::Chef::ListCookbooks do

  fake_fs!

  describe "#perform" do
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

end
