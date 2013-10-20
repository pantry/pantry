require 'unit/test_helper'
require 'pantry/communication/wait_list'
require 'pantry/communication/message'

describe Pantry::Communication::WaitList do

  before do
    Celluloid.init

    @wait_list = Pantry::Communication::WaitList.new
    @message = Pantry::Communication::Message.new("do_something")
    @message.identity = "identity"

    @future = @wait_list.wait_for("identity", @message)
  end

  it "creates and returns a future waiting for a response for the given identity and message" do
    assert !@future.ready?, "Future should not have been ready with information"
  end

  it "knows if the given message matches a waiting future" do
    assert @wait_list.waiting_for?(@message), "Wait List should be waiting for this message"
  end

  it "matches message identity and message type when finding futures" do
    @message.identity = "not me"

    assert !@wait_list.waiting_for?(@message), "Wait List should not be waiting for 'not me'"

    @message.identity = "identity"
    @message.type     = "some other type"

    assert !@wait_list.waiting_for?(@message), "Wait List should not be waiting for 'some other type'"
  end

  it "fulfills the waiting future if a message is received matching the waiting future" do
    @message.identity = "identity"
    @message          << "The new body"
    @wait_list.received(@message)

    assert @future.ready?, "Future has not yet received information"
    assert_equal ["The new body"], @future.value.body
  end

end
