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

    # Find info for Client that matches the given identity
    def find(identity)
      if found = @clients[identity]
        found.client
      else
        nil
      end
    end

    # Find and return all clients who will receive messages
    # on the given stream or ClientFilter.
    #
    # If this method is given a block, the block will be processed as
    # a #map of the list of clients and records. Block expected to be
    # of the form:
    #
    #   all_matching(filter) do |client, record|
    #     ...
    #   end
    #
    # The `record` contains internal knowledge of the Client's activity.
    # See ClientRecord for what's contained.
    def all_matching(stream_or_filter)
      found_client_records =
        case stream_or_filter
        when String
          select_records_matching do |record|
            record.client.filter.matches?(stream_or_filter)
          end
        else
          select_records_matching do |record|
            stream_or_filter.includes?(record.client.filter)
          end
        end

      if block_given?
        found_client_records.map do |record|
          yield(record.client, record)
        end
      else
        found_client_records.map(&:client)
      end
    end

    protected

    def select_records_matching
      selected_records = @clients.clone.select do |identity, record|
        yield(record)
      end

      selected_records.values
    end

    class ClientRecord
      attr_reader :client, :last_checked_in_at

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
