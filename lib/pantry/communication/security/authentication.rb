module Pantry
  module Communication
    module Security

      # This class implements and manages the ZAP handler.
      # For any connecting client, this handler receives a request to
      # authenticate the Client. If the Client is allowed in, all proceeds as
      # normal. If a Client is not allowed in then the connection is dropped.
      #
      # For Pantry, this is a very strict authentication mechanism that only
      # allows Clients in whos public keys are in the server_keys.yml keystore.
      # It also rejects any attempts to authenticate with a mechanism other than CURVE.
      #
      # ZAP: ZeroMQ Authentication Protocol :: http://rfc.zeromq.org/spec:27
      class Authentication
        include Celluloid::ZMQ
        finalizer :shutdown

        def initialize(key_store)
          @key_store = key_store

          @socket = Celluloid::ZMQ::RepSocket.new
          @socket.linger = 0
        end

        def open
          @socket.bind("inproc://zeromq.zap.01")
          @running = true
          self.async.process_requests
        end

        def shutdown
          @socket.close
          @running = false
        end

        def process_requests
          while @running
            process_next_request
          end
        end

        def process_next_request
          request = read_next_request

          response_code, response_text = authenticate_request(request)

          if response_code == "200"
            Pantry.logger.debug("[AUTH] Client authentication successful")
          else
            Pantry.logger.debug("[AUTH] Client authentication rejected: #{response_text}")
          end

          write_response(request, response_code, response_text)
        end

        def read_next_request
          request = []
          begin
            request << @socket.read
          end while @socket.more_parts?
          request
        end

        def authenticate_request(request)
          mechanism  = request[5]
          client_key = request[6]

          if mechanism != "CURVE"
            response_code = "400"
            response_text = "Invalid Mechanism"
            ["400", "Invalid Mechanism"]
          else
            authenticate_client(client_key)
          end
        end

        def authenticate_client(client_key)
          if @key_store.known_client?(client_key)
            ["200", "OK"]
          else
            ["400", "Unknown Client"]
          end
        end

        def write_response(request, response_code, response_text)
          @socket.write([
            request[0],    # Version
            request[1],    # Sequence / Request id
            response_code,
            response_text,
            "",            # username
            ""             # metadata
          ])
        end
      end

    end
  end
end
