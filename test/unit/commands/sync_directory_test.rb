require 'unit/test_helper'

describe Pantry::Commands::SyncDirectory do

  fake_fs!

  class MySyncTest < Pantry::Commands::SyncDirectory
    def server_directory(local_root)
      local_root.join("copy", "from", "dir")
    end

    def client_directory(local_root)
      local_root.join("copy", "to")
    end
  end

  it "asks Server for all files in a directory, returning name and contents" do
    client = stub_everything

    response = Pantry::Message.new
    response << ["file1.txt", %|some content here|]
    response << ["file2.rb",  %|def main; end;|]

    client.expects(:send_request).with do |message|
      assert_equal "DownloadDirectory", message.type
      assert_equal "copy/from/dir", message.body[0]
    end.returns(mock(:value => response))

    command = MySyncTest.new
    command.client = client
    command.perform(Pantry::Message.new)

    file1 = Pantry.root.join("copy", "to", "file1.txt")
    assert File.exists?(file1), "Did not write the first file"
    assert_equal "some content here", File.read(file1)

    file2 = Pantry.root.join("copy", "to", "file2.rb")
    assert File.exists?(file2), "Did not write the second file"
    assert_equal "def main; end;", File.read(file2)
  end

end
