require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  mock_ui!

  it "can ask for all known nodes" do
    set_up_environment(ports_start_at: 10200)

    Pantry::CLI.new(
      ["status"],
      identity: "test_client"
    ).run

    assert_match /#{@client1.identity}/, stdout, "Did not contain line for client1"
    assert_match /#{@client2.identity}/, stdout, "Did not contain line for client2"
  end

  it "can limit the query to a subset of clients" do
    set_up_environment(ports_start_at: 10210)

    cli = Pantry::CLI.new(
      ["-a", "chatbot", "status"],
      identity: "test_client"
    )

    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    cli.run

    assert_equal 2, stdout.split("\n").length

    assert_match /client3/, stdout, "Did not contain line for client3"
    assert_match /client4/, stdout, "Did not contain line for client4"

    client3.shutdown
    client4.shutdown
  end

end
