require 'unit/test_helper'

describe Pantry::Chef::UploadRole do

  it "uploads the resulting file to the application's chef environments directory" do
    command = Pantry::Chef::UploadRole.new
    assert_equal Pantry.root.join("applications", "pantry", "chef", "roles"),
      command.upload_directory(application: "pantry")
  end

end
