require 'unit/test_helper'

describe Pantry::Communication::Security::NullSecurity do

  it "exists" do
    client = Pantry::Communication::Security::NullSecurity.new
    assert_not_nil client
  end

end
