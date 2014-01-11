require 'unit/test_helper'

describe Pantry::Chef::DownloadRoles do

  describe "#perform" do
    fake_fs!

    it "returns filename and contents of all roles for the client's application" do
      message = Pantry::Message.new

      client = stub
      client.stubs(:application).returns("pantry")

      server = mock
      server.expects(:client_who_sent).with(message).returns(client)

      FileUtils.mkdir_p(Pantry.root.join("applications", "pantry", "chef", "roles"))
      FileUtils.touch(Pantry.root.join("applications", "pantry", "chef", "roles", "app.rb"))
      FileUtils.touch(Pantry.root.join("applications", "pantry", "chef", "roles", "db.rb"))

      command = Pantry::Chef::DownloadRoles.new
      command.server = server

      response = command.perform(message)

      assert_equal 2, response.length
      assert_equal ["app.rb", ""], response[0]
      assert_equal ["db.rb", ""], response[1]
    end

  end

end

