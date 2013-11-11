module Pantry

  # The ClientRegistry keeps track of clients who've checked in and supports
  # various querying requests against the list of known clients.
  class ClientRegistry

    def initialize
      clear!
    end

    # Return all known clients
    def all
      @clients.map {|identity, record| record.client }
    end

    # Clear out the registry entirely
    def clear!
      @clients = Hash.new {|hash, key| hash[key] = ClientRecord.new }
    end

    # Check in a client
    def check_in(client)
      @clients[client.identity].check_in(client)
    end

    # Has the given client checked in?
    def include?(client)
      @clients[client.identity].checked_in?
    end

    # Find and return all clients who will receive messages
    # on the given stream or ClientFilter
    def all_matching(stream_or_filter)
      case stream_or_filter
      when String
        select_clients_matching do |client|
          client.filter.matches?(stream_or_filter)
        end
      else
        select_clients_matching do |client|
          stream_or_filter.includes?(client.filter)
        end
      end
    end

    protected

    def select_clients_matching
      selected_records = @clients.select do |identity, record|
        yield(record.client)
      end

      selected_records.values.map(&:client)
    end

    class ClientRecord
      attr_reader :client

      def initialize
        @client = nil
        @last_checked_in_at = nil
      end

      def check_in(client)
        @client = client
        @last_checked_in_at = Time.now
      end

      def checked_in?
        !@last_checked_in_at.nil?
      end
    end

  end
end
