require 'unit/test_helper'

describe Pantry::Chef::UploadEnvironment do

  it "uploads the resulting file to the application's chef environments directory" do
    command = Pantry::Chef::UploadEnvironment.new
    assert_equal Pantry.root.join("applications", "pantry", "chef", "environments"),
      command.upload_directory(application: "pantry")
  end

end
