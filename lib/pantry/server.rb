module Pantry

  # The Pantry Server
  class Server
    include Celluloid

    # This server's Identity. By default this is the server's hostname but can be specified manually.
    attr_accessor :identity

    # Registry of clients this Server knows about
    attr_reader :client_registry

    # Initialize the Pantry Server
    def initialize(network_stack_class = Communication::Server)
      @commands   = ServerCommands.new(self)
      @networking = network_stack_class.new(self)
      @identity   = current_hostname
      @clients    = []

      @client_registry = ClientRegistry.new
    end

    # Start up the networking stack and start the server
    def run
      @networking.run
      Pantry.logger.info("[#{@identity}] Server running")
    end

    # Close down networking and clean up resources
    def shutdown
      Pantry.logger.info("[#{@identity}] Server Shutting Down")
      @networking.shutdown
    end

    # Mark a client as checked-in
    def register_client(client)
      Pantry.logger.info("[#{@identity}] Received client registration :: #{client.identity}")
      @client_registry.check_in(client)
    end

    # Broadcast a message to all clients, optionally filtering for certain clients.
    def publish_message(message, filter = Communication::ClientFilter.new)
      Pantry.logger.debug("[#{@identity}] Publishing #{message.inspect} to #{filter.stream.inspect}")
      message.to = filter.stream
      @networking.publish_message(message)
    end

    # Callback from the network when a message is received unsolicited from a client.
    # If the message received is unhandleable by this Server, the message is forwarded
    # on down to the clients who match the message's to line.
    def receive_message(message)
      Pantry.logger.debug("[#{@identity}] Received message #{message.inspect}")
      if @commands.can_handle?(message)
        results = @commands.process(message)

        if message.requires_response?
          Pantry.logger.debug("[#{@identity}] Returning results #{results.inspect}")
          send_results_back_to_requester(message, results)
        end
      else
        forward_message(message)
        matched_clients = @client_registry.all_matching(message.to).map(&:identity)

        Pantry.logger.debug("[#{@identity}] Forwarding message on to #{matched_clients.inspect}")
        send_results_back_to_requester(message, matched_clients)
      end
    end

    # Send a request to the Client(s) with the given identity.
    # Returns a Future object, use #value to get the response from the Client
    # when it's available.
    def send_request(client, message)
      message.requires_response!
      message.to = client.identity

      Pantry.logger.debug("[#{@identity}] Sending request #{message.inspect}")

      @networking.send_request(message)
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message << results

      @networking.publish_message(response_message)
    end

    def forward_message(message)
      @networking.forward_message(message)
    end

  end
end
