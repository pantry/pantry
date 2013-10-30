module Pantry

  # The ClientRegistry keeps track of clients who've checked in and supports
  # various querying requests against the list of known clients.
  class ClientRegistry

    def initialize
      @clients = []
    end

    # Check in a client
    def check_in(client)
      @clients << client
    end

    # Has the given client checked in?
    def include?(client)
      @clients.include?(client)
    end

    # Find and return all clients who will receive messages
    # on the given stream
    def all_matching(stream)
      @clients.select do |client|
        client.filter.matches?(stream)
      end
    end

  end
end
