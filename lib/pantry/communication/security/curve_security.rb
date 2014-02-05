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
            Pantry.logger.info("Configuring Client to use Curve encryption")
          end

          def configure_socket(socket)
            socket.set(::ZMQ::CURVE_SERVERKEY, @key_store.server_public_key)
            socket.set(::ZMQ::CURVE_PUBLICKEY, @key_store.public_key)
            socket.set(::ZMQ::CURVE_SECRETKEY, @key_store.private_key)
          end

        end

        class Server

          def initialize
            @key_store = CurveKeyStore.new("server_keys")
            Pantry.logger.info("Configuring Server to use Curve encryption")
          end

          def configure_socket(socket)
            socket.set(::ZMQ::CURVE_SERVER,    1)
            socket.set(::ZMQ::CURVE_SECRETKEY, @key_store.private_key)
          end

        end

      end

    end
  end
end
