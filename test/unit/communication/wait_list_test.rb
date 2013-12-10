require 'unit/test_helper'

describe Pantry::Communication::WaitList do

  before do
    Celluloid.init

    @wait_list = Pantry::Communication::WaitList.new
  end

  describe "One shot messages" do

    before do
      @message = Pantry::Message.new("do_something")
      @future = @wait_list.wait_for(@message)
    end

    it "creates and returns a future waiting for a response for the given identity and message" do
      assert !@future.ready?, "Future should not have been ready with information"
    end

    it "knows if the given message matches a waiting future" do
      assert @wait_list.waiting_for?(@message), "Wait List should be waiting for this message"
    end

    it "fulfills the waiting future if a message is received matching the waiting future" do
      @message.from = "identity"
      @message << "The new body"
      @wait_list.received(@message)

      assert @future.ready?, "Future has not yet received information"
      assert_equal ["The new body"], @future.value.body

      assert_false @wait_list.waiting_for?(@message), "Future was not removed from the wait list"
    end

    it "allows multiple entries for a given identity and message type" do
      wait_list = Pantry::Communication::WaitList.new

      m1 = Pantry::Message.new("do_something")
      m1.from = "client"

      m2 = Pantry::Message.new("do_something")
      m2.from = "client"

      m3 = Pantry::Message.new("do_something")
      m3.from = "client"

      future1 = wait_list.wait_for(m1)
      future2 = wait_list.wait_for(m2)
      future3 = wait_list.wait_for(m3)

      assert wait_list.waiting_for?(m1)

      wait_list.received(m1)
      wait_list.received(m2)
      wait_list.received(m3)

      assert future1.ready?, "First future was not ready"
      assert future2.ready?, "Second future was not ready"
      assert future3.ready?, "Third future was not ready"
    end

  end

  describe "Persistent Messages" do

    class WantsLotsOfMessages
      include Celluloid

      attr_reader :messages
      attr_reader :message_count

      def initialize
        @messages = []
      end

      def uuid
        "uuid"
      end

      def receive_message(message)
        @messages << message
      end

      def finished?
        @messages.length == 3
      end
    end

    before do
      @receiver = WantsLotsOfMessages.new
      @wait_list.wait_for_persistent(@receiver)
    end

    it "sends all messages matching the UUID to the receiver" do
      m1 = Pantry::Message.new
      m1.uuid = "uuid"

      m2 = Pantry::Message.new
      m2.uuid = "uuid"

      m3 = Pantry::Message.new
      m3.uuid = "not-uuid"

      m4 = Pantry::Message.new
      m4.uuid = "uuid"

      @wait_list.received(m1)
      @wait_list.received(m2)
      @wait_list.received(m3)
      @wait_list.received(m4)

      assert_equal [m1, m2, m4], @receiver.messages
    end

    it "shuts off the receiver if finished? returns true" do
      m1 = Pantry::Message.new
      m1.uuid = "uuid"

      5.times do
        @wait_list.received(m1)
      end

      assert_equal [m1, m1, m1], @receiver.messages
    end

  end

end
