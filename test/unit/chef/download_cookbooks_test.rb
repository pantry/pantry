require 'unit/test_helper'

describe Pantry::Chef::DownloadCookbooks do

  fake_fs!

  it "has a custom type" do
    assert_equal "Chef::DownloadCookbooks", Pantry::Chef::DownloadCookbooks.command_type
  end

  describe "#perform" do
#    it "builds file senders for the latest version of all uploaded cookbooks" do
#      server = Pantry::Server.new
#
#      cookbooks = [
#        Pantry.root.join("chef", "cookbooks", "mini", "1.0.0.tgz"),
#        Pantry.root.join("chef", "cookbooks", "mini", "2.0.0.tgz"),
#        Pantry.root.join("chef", "cookbooks", "ruby", "1.0.0.tgz"),
#        Pantry.root.join("chef", "cookbooks", "pantry", "1.0.0.tgz")
#      ]
#
#      cookbooks.each do|c|
#        FileUtils.mkdir_p(File.dirname(c))
#        FileUtils.touch(c)
#      end
#
#      # Because FakeFS doesn't work with Tempfile
#      Digest::SHA256.stubs(:file).returns(stub(:hexdigest => "deadbeef"))
#
#      command = Pantry::Chef::DownloadCookbooks.new
#      command.server_or_client = server
#      senders = command.perform(Pantry::Message.new)
#
#      assert_equal 3, senders.length
#
#      assert_equal "mini",     senders[0][0]
#      assert_equal 36,         senders[0][1].length
#      assert_equal 0,          senders[0][2]
#      assert_equal "deadbeef", senders[0][3]
#
#      assert_equal "pantry", senders[1][0]
#      assert_equal "ruby",   senders[2][0]
#
#      assert senders[0][1] != senders[1][1], "UUID was shared between mini and pantry"
#      assert senders[1][1] != senders[2][1], "UUID was shared between pantry and ruby"
#    end
  end

end
