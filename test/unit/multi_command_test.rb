require 'unit/test_helper'

describe Pantry::MultiCommand do

  class TestPart1 < Pantry::Command
    def perform(message)
      [1, client.identity, message.type]
    end
  end

  class TestPart2 < Pantry::Command
    def perform(message)
      [2, client.identity, message.type]
    end
  end

  class TestPart3 < Pantry::Command
    def perform(message)
      [3, client.identity, message.type]
    end
  end

  class TestMultiCommand < Pantry::MultiCommand
    performs [
      TestPart1,
      TestPart2,
      TestPart3
    ]
  end

  it "runs multiple commands in order, combining return values" do
    client = Pantry::Client.new identity: "Client"
    command = TestMultiCommand.new
    command.client = client

    results = command.perform(Pantry::Message.new("Message"))

    assert_equal [
      [1, "Client", "Message"],
      [2, "Client", "Message"],
      [3, "Client", "Message"],
    ], results
  end

end
