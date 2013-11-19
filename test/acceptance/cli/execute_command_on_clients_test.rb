require 'acceptance/test_helper'

describe "CLI requests information from individual clients" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "receives responses from each client asked" do
    cli = Pantry::CLI.new(identity: "cli1")
    cli.run

    filter = Pantry::Communication::ClientFilter.new(application: "pantry")

    response = cli.request(filter, "echo", "This is Neat")
    all = response.messages

    all = response.messages.sort {|a, b| a.from <=> b.from }

    p all

    assert_equal @client1.identity, all[0].from
    assert_equal ["This is Neat"],  all[0].body

    assert_equal @client2.identity, all[1].from
    assert_equal ["This is Neat"],  all[1].body
  end

end
