require 'unit/test_helper'

describe Pantry::Chef::SendCookbooks do

  fake_fs!

  describe "#perform" do

    it "takes the list of receivers and builds senders, passing in the proper cookbook file" do
      message = Pantry::Message.new
      message << ["mini",   "receiver_ident",  "file_uuid"]
      message << ["pantry", "receiver_ident2", "file_uuid2"]

      cookbooks = [
        Pantry.root.join("chef", "cookbook-cache", "mini.tgz"),
        Pantry.root.join("chef", "cookbook-cache", "pantry.tgz")
      ]

      cookbooks.each do|c|
        FileUtils.mkdir_p(File.dirname(c))
        FileUtils.touch(c)
      end

      server = mock
      server.expects(:send_file).with(
        Pantry.root.join("chef", "cookbook-cache", "mini.tgz"),
        "receiver_ident",
        "file_uuid"
      )

      server.expects(:send_file).with(
        Pantry.root.join("chef", "cookbook-cache", "pantry.tgz"),
        "receiver_ident2",
        "file_uuid2"
      )

      command = Pantry::Chef::SendCookbooks.new
      command.server = server
      command.perform(message)
    end

  end

end
