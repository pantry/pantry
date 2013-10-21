require 'unit/test_helper'
require 'pantry/communication/wait_list'
require 'pantry/communication/message'

describe Pantry::Communication::WaitList do

  before do
    Celluloid.init

    @wait_list = Pantry::Communication::WaitList.new
    @message = Pantry::Communication::Message.new("do_something")
    @message.source = "identity"

    @future = @wait_list.wait_for("identity", @message)
  end

  it "creates and returns a future waiting for a response for the given identity and message" do
    assert !@future.ready?, "Future should not have been ready with information"
  end

  it "knows if the given message matches a waiting future" do
    assert @wait_list.waiting_for?(@message), "Wait List should be waiting for this message"
  end

  it "matches message identity and message type when finding futures" do
    @message.source = "not me"

    assert !@wait_list.waiting_for?(@message), "Wait List should not be waiting for 'not me'"

    @message.source = "identity"
    @message.type   = "some other type"

    assert_false @wait_list.waiting_for?(@message), "Wait List should not be waiting for 'some other type'"
  end

  it "fulfills the waiting future if a message is received matching the waiting future" do
    @message.source = "identity"
    @message        << "The new body"
    @wait_list.received(@message)

    assert @future.ready?, "Future has not yet received information"
    assert_equal ["The new body"], @future.value.body

    assert_false @wait_list.waiting_for?(@message), "Future was not removed from the wait list"
  end

  it "allows multiple entries for a given identity and message type" do
    wait_list = Pantry::Communication::WaitList.new

    m1 = Pantry::Communication::Message.new("do_something")
    m1.source = "client"

    m2 = Pantry::Communication::Message.new("do_something")
    m2.source = "client"

    m3 = Pantry::Communication::Message.new("do_something")
    m3.source = "client"

    future1 = wait_list.wait_for("client", m1)
    future2 = wait_list.wait_for("client", m2)
    future3 = wait_list.wait_for("client", m3)

    assert wait_list.waiting_for?(m1)

    wait_list.received(m1)
    wait_list.received(m2)
    wait_list.received(m3)

    assert future1.ready?, "First future was not ready"
    assert future2.ready?, "Second future was not ready"
    assert future3.ready?, "Third future was not ready"
  end

end
