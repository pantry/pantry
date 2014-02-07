require 'acceptance/test_helper'

describe "CLI requests information from individual clients" do

  mock_ui!

  it "receives responses from each client asked" do
    set_up_environment(ports_start_at: 10100)

    Pantry::CLI.new(
      ["-a", "pantry", "echo", "This is Neat"],
      identity: "cli1"
    ).run

    assert_match %r|#{@client1.identity} echo's "This is Neat"|, stdout
    assert_match %r|#{@client2.identity} echo's "This is Neat"|, stdout
  end

  it "can target specific clients for the commands sent" do
    set_up_environment(ports_start_at: 10110)

    Pantry::CLI.new(
      ["-a", "pantry", "-e", "test", "-r", "app1", "echo", "This is Neat"],
      identity: "cli1"
    ).run

    assert_equal "#{@client1.identity} echo's \"This is Neat\"\n", stdout
  end

end
