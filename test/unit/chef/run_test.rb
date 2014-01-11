require 'unit/test_helper'

describe Pantry::Chef::Run do

  it "has a custom type" do
    assert_equal "Chef::Run", Pantry::Chef::Run.message_type
  end

end
