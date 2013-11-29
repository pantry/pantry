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

  it "does not duplicate clients in the list from multiple check-ins" do
    @registry.check_in(@c1)
    @registry.check_in(@c1)
    @registry.check_in(@c1)

    assert_equal [@c1, @c2], @registry.all
  end

  it "returns all known clients that match the given stream" do
    assert_equal [@c1, @c2], @registry.all_matching("")
    assert_equal [@c1], @registry.all_matching("pantry.test")
    assert_equal [@c1], @registry.all_matching("client1")
    assert_equal [@c2], @registry.all_matching("client2")
  end

  it "returns all known clients that match a given ClientFilter" do
    assert_equal [@c1, @c2], @registry.all_matching(Pantry::Communication::ClientFilter.new)

    filter = Pantry::Communication::ClientFilter.new(application: "pantry", environment: "test")
    assert_equal [@c1], @registry.all_matching(filter)

    filter = Pantry::Communication::ClientFilter.new(environment: "test")
    assert_equal [@c2], @registry.all_matching(filter)
  end

  it "processes each found client via the block if given" do
    found = @registry.all_matching(Pantry::Communication::ClientFilter.new) do |client, record|
      client.identity
    end

    assert_equal [@c1.identity, @c2.identity], found
  end

  it "can return all known clients" do
    assert_equal [@c1, @c2], @registry.all
  end

end
