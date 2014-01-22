module Pantry
  module Communication
    module Security

      # ZeroMQ Curve encryption strategy.
      # For details about how the Curve encryption works in ZeroMQ, check out
      # the following:
      #
      # * http://api.zeromq.org/4-0:zmq-curve
      # * http://curvezmq.org/
      #
      class CurveSecurity

        def self.client
          Client.new
        end

        def self.server
          Server.new
        end

        # Client-side handling of Curve encryption.
        class Client

          def initialize
            @key_store = CurveKeyStore.new("client_keys")
          end

          def configure_socket(socket)
            Pantry.logger.debug("[Curve] Configuring socket with #{@key_store.get("server.pub")}")

            socket.setsockopt(::ZMQ::CURVE_SERVERKEY, @key_store.get("server.pub"))
            socket.setsockopt(::ZMQ::CURVE_PUBLICKEY, @key_store.public_key)
            socket.setsockopt(::ZMQ::CURVE_SECRETKEY, @key_store.private_key)
          end

        end

        class Server

          def initialize
            @key_store = CurveKeyStore.new("server_keys")
          end

          def configure_socket(socket)
            Pantry.logger.debug("[Curve] Configuring socket with #{@key_store.private_key}")

            socket.setsockopt(::ZMQ::CURVE_SERVER,    1)
            socket.setsockopt(::ZMQ::CURVE_SECRETKEY, @key_store.private_key)
          end

        end

      end

    end
  end
end
