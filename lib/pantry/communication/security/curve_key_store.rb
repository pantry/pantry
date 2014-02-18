module Pantry
  module Communication
    module Security

      # CurveKeyStore manages the storage, reading, and writing of all
      # Curve-related key-pairs.
      #
      # Clients keep track of the public key of the server they talk to
      # Servers keep track of the list of public keys of Clients who are
      # allowed to connect.
      #
      # All keys are stored under Pantry.root/security/curve
      class CurveKeyStore

        attr_reader :public_key, :private_key, :server_public_key

        def initialize(my_key_pair_name)
          @base_key_dir  = Pantry.root.join("security", "curve")
          @my_keys_file  = @base_key_dir.join("#{my_key_pair_name}.yml")
          @known_clients = []

          ensure_directory_structure
          check_or_generate_my_keys
        end

        # Check if the given client public key is known by this server or
        # not. To facilitate the initial setup process of a new Pantry Server,
        # this will allow and store the first client to connect to this server
        # and will write out that client's public key as valid.
        #
        # Used solely by the Server
        def known_client?(client_public_key)
          encoded_key = z85_encode(client_public_key)
          if @known_clients.empty?
            store_known_client(encoded_key)
            true
          else
            @known_clients.include?(encoded_key)
          end
        end

        # Generate and store a new Client pub/priv key pair
        # Only the Public key is stored locally for authentication purposes.
        # Returns a hash of all relevant keys for the Client to connect
        # and Auth.
        def create_client
          client_public, client_private = ZMQ::Util.curve_keypair
          store_known_client(client_public)

          {
            server_public_key: @public_key,
            public_key: client_public,
            private_key: client_private
          }
        end

        protected

        # TODO Move this logic into ffi-rzmq proper
        def z85_encode(binary_key)
          encoded = FFI::MemoryPointer.from_string(' ' * 41)
          LibZMQ::zmq_z85_encode(encoded, binary_key, 32)
        end

        def ensure_directory_structure
          FileUtils.mkdir_p(@base_key_dir)
          FileUtils.chmod(0700, @base_key_dir)
        end

        def check_or_generate_my_keys
          if File.exists?(@my_keys_file)
            load_current_key_pair
          end

          generate_missing_keys
        end

        def load_current_key_pair
          keys = YAML.load_file(@my_keys_file)
          @public_key = keys["public_key"]
          @private_key = keys["private_key"]
          @server_public_key = keys["server_public_key"]
          @known_clients = keys["client_keys"] || []
        end

        def generate_missing_keys
          if @public_key.nil? && @private_key.nil?
            @public_key, @private_key = ZMQ::Util.curve_keypair
            save_keys
          end
        end

        def store_known_client(client_public_key)
          @known_clients << client_public_key
          save_keys
        end

        def save_keys
          File.open(@my_keys_file, "w+") do |f|
            keys = {
              "private_key" => @private_key,
              "public_key" => @public_key
            }

            if @server_public_key
              keys["server_public_key"] = @server_public_key
            end

            if @known_clients.length > 0
              keys["client_keys"] = @known_clients
            end

            f.write YAML.dump(keys)
          end
        end
      end

    end
  end
end
