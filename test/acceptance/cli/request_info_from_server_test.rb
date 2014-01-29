require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  it "can ask for all known nodes" do
    set_up_environment(ports_start_at: 10200)

    cli = Pantry::CLI.new(
      ["status"],
      identity: "test_client"
    )
    out, err = capture_io { cli.run }

    assert out =~ /#{@client1.identity}/, "Did not contain line for client1"
    assert out =~ /#{@client2.identity}/, "Did not contain line for client2"
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

    out, err = capture_io { cli.run }

    assert_equal 2, out.split("\n").length

    assert out =~ /client3/, "Did not contain line for client3"
    assert out =~ /client4/, "Did not contain line for client4"

    client3.shutdown
    client4.shutdown
  end

end
