require 'unit/test_helper'

describe Pantry::Chef::DownloadEnvironments do

  describe "#perform" do
    fake_fs!

    it "returns filename and contents of all environments for the client's application" do
      message = Pantry::Message.new

      client = stub
      client.stubs(:application).returns("pantry")

      server = mock
      server.expects(:client_who_sent).with(message).returns(client)

      FileUtils.mkdir_p(Pantry.root.join("applications", "pantry", "chef", "environments"))
      FileUtils.touch(
        Pantry.root.join("applications", "pantry", "chef", "environments", "staging.rb"))
      FileUtils.touch(
        Pantry.root.join("applications", "pantry", "chef", "environments", "test.rb"))

      command = Pantry::Chef::DownloadEnvironments.new
      command.server = server

      response = command.perform(message)

      assert_equal 2, response.length
      assert_equal ["staging.rb", ""], response[0]
      assert_equal ["test.rb", ""], response[1]
    end

  end

end

