module Pantry

  # The ClientRegistry keeps track of clients who've checked in and supports
  # various querying requests against the list of known clients.
  class ClientRegistry

    def initialize
      @clients = Set.new
    end

    # Return all known clients
    def all
      @clients.to_a
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
    # on the given stream or ClientFilter
    def all_matching(stream_or_filter)
      case stream_or_filter
      when String
        @clients.select do |client|
          client.filter.matches?(stream_or_filter)
        end
      else
        @clients.select do |client|
          stream_or_filter.includes?(client.filter)
        end
      end
    end

  end
end
