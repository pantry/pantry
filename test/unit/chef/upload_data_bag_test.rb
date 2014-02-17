require 'unit/test_helper'

describe Pantry::Chef::UploadDataBag do

  fake_fs!

  it "uploads the resulting file to the application's chef environments directory" do
    command = Pantry::Chef::UploadDataBag.new
    assert_equal Pantry.root.join("applications", "pantry", "chef", "data_bags", "settings"),
      command.upload_directory({application: "pantry", type: "settings"})
  end

  it "defaults the data bag type to the file's directory" do
    FileUtils.mkdir_p("data_bags/settings")
    FileUtils.touch("data_bags/settings/test.json")

    command = Pantry::Chef::UploadDataBag.new("data_bags/settings/test.json")

    message = command.prepare_message({application: "pantry"})

    assert_equal({application: "pantry", type: "settings"}, message.body[0])
  end

end
