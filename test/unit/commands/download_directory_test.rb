require 'unit/test_helper'

describe Pantry::Commands::DownloadDirectory do

  fake_fs!

  it "builds a message with the given directory" do
    message = Pantry::Commands::DownloadDirectory.new("path/here").to_message
    assert_equal "path/here", message.body[0]
  end

  it "returns filename and contents of all files inside of the requested directory" do
    root_dir = Pantry
    message = Pantry::Message.new
    message << "copy/from"

    FileUtils.mkdir_p(Pantry.root.join("copy", "from"))
    FileUtils.touch(Pantry.root.join("copy", "from", "app.rb"))
    FileUtils.touch(Pantry.root.join("copy", "from", "db.rb"))

    command = Pantry::Commands::DownloadDirectory.new
    response = command.perform(message)

    assert_equal 2, response.length
    assert_equal ["app.rb", ""], response[0]
    assert_equal ["db.rb", ""], response[1]
  end

  it "does nested read of the given directory" do
    root_dir = Pantry
    message = Pantry::Message.new
    message << "copy/from"

    FileUtils.mkdir_p(Pantry.root.join("copy", "from", "here", "there"))
    FileUtils.touch(Pantry.root.join("copy", "from", "here", "there", "app.rb"))
    FileUtils.touch(Pantry.root.join("copy", "from", "here", "there", "db.rb"))

    command = Pantry::Commands::DownloadDirectory.new
    response = command.perform(message)

    assert_equal 2, response.length
    assert_equal ["here/there/app.rb", ""], response[0]
    assert_equal ["here/there/db.rb", ""], response[1]
  end

  it "does not allow path traversal attacks" do
    root_dir = Pantry
    message = Pantry::Message.new
    message << "../../../../etc/"

    command = Pantry::Commands::DownloadDirectory.new
    response = command.perform(message)

    assert_equal 0, response.length
  end

end

