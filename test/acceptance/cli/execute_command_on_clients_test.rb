require 'acceptance/test_helper'

describe "CLI requests information from individual clients" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

#  it "receives responses from each client asked" do
#    cli = Pantry::CLI.new(identity: "cli1")
#    cli.run
#
#    filter = Pantry::Communication::ClientFilter.new(application: "pantry")
#
#    # `pantry execute whoami`
#    future = cli.request(filter, "execute", "whoami")
#
#    response = Timeout::timeout(2) { future.value }
#
#    p response
#
#    # May find any number of clients, including the CLI client, so just look
#    # for a few we know should be there
#    assert response.body.include?(@client1.identity), "Response did not include the identity of Client 1"
#    assert response.body.include?(@client2.identity), "Response did not include the identity of Client 2"
#  end

end
