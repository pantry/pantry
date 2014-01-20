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

        class MissingServerPublicKey < Exception; end

        def self.client
          Client.new
        end

        def self.server
          Server.new
        end

        # Client-side handling of Curve encryption.
        class Client

          def initialize
            @base_key_dir = Pantry.root.join("security", "curve")
            @my_keys_file = @base_key_dir.join("my_keys.yml")

            ensure_directory_structure
            check_or_generate_client_keys
          end

          def configure_socket(socket)
            server_public_key_file = @base_key_dir.join("server.pub")

            unless File.exists?(server_public_key_file)
              raise MissingServerPublicKey,
                "No server public key found, expecting: #{@base_key_dir}/server.pub"
            end

            @server_public_key = File.read(server_public_key_file).strip

            socket.setsockopt(::ZMQ::CURVE_SERVERKEY, @server_public_key)
            socket.setsockopt(::ZMQ::CURVE_PUBLICKEY, @public_key)
            socket.setsockopt(::ZMQ::CURVE_SECRETKEY, @private_key)
          end

          protected

          def ensure_directory_structure
            FileUtils.mkdir_p(@base_key_dir)
            FileUtils.chmod(0700, @base_key_dir)
          end

          def check_or_generate_client_keys
            if File.exists?(@my_keys_file)
              load_current_key_pair
            else
              generate_new_key_pair
            end
          end

          def load_current_key_pair
            keys = YAML.load_file(@my_keys_file)
            @public_key = keys["public_key"]
            @private_key = keys["private_key"]
          end

          def generate_new_key_pair
            @public_key, @private_key = ZMQ::Util.curve_keypair

            File.open(@my_keys_file, "w+") do |f|
              f.write YAML.dump({"private_key" => @private_key, "public_key" => @public_key})
            end
          end

        end

        class Server
        end

      end

    end
  end
end
