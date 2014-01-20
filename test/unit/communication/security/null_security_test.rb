require 'unit/test_helper'

describe Pantry::Communication::Security::NullSecurity do

  it "exists" do
    client = Pantry::Communication::Security::NullSecurity.new
    assert_not_nil client
  end

  it "does nothing for configuring sockets" do
    client = Pantry::Communication::Security::NullSecurity.new
    client.configure_socket("something")
  end

end
