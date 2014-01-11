require 'unit/test_helper'

describe Pantry::Chef::ListCookbooks do

  fake_fs!

  describe "#perform" do
    it "returns the list of cookbooks and latest version known" do
      cookbooks = [
        Pantry.root.join("chef", "cookbooks", "mini", "1.0.0.tgz"),
        Pantry.root.join("chef", "cookbooks", "mini", "2.0.0.tgz"),
        Pantry.root.join("chef", "cookbooks", "ruby", "1.0.0.tgz"),
        Pantry.root.join("chef", "cookbooks", "pantry", "1.0.0.tgz")
      ]

      cookbooks.each do|c|
        FileUtils.mkdir_p(File.dirname(c))
        FileUtils.touch(c)
      end

      Digest::SHA256.stubs(:file).returns(stub(:hexdigest => "deadbeef"))

      command = Pantry::Chef::ListCookbooks.new
      cookbook_list = command.perform(Pantry::Message.new)

      assert_equal [
        ["mini",   "2.0.0", 0, "deadbeef"],
        ["pantry", "1.0.0", 0, "deadbeef"],
        ["ruby",   "1.0.0", 0, "deadbeef"]
      ], cookbook_list
    end
  end

end
