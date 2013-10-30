require 'unit/test_helper'

describe Pantry::ClientRegistry do

  before do
    @c1 = Pantry::Client.new identity: "client1", application: "pantry", environment: "test"
    @c2 = Pantry::Client.new identity: "client2", environment: "test"

    @registry = Pantry::ClientRegistry.new
    @registry.check_in(@c1)
    @registry.check_in(@c2)
  end

  it "marks a client as checked in" do
    assert @registry.include?(@c1)
    assert @registry.include?(@c2)
  end

  it "returns all known clients that match the given stream" do
    assert_equal [@c1, @c2], @registry.all_matching("")
    assert_equal [@c1], @registry.all_matching("pantry.test")
    assert_equal [@c1], @registry.all_matching("client1")
    assert_equal [@c2], @registry.all_matching("client2")
  end

end
