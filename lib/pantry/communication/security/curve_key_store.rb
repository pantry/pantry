module Pantry
  module Communication
    module Security

      # CurveKeyStore manages the storage, reading, and writing of all
      # Curve-related key-pairs.
      #
      # All keys are stored under Pantry.root/security/curve
      class CurveKeyStore

        attr_reader :public_key, :private_key, :server_public_key

        def initialize(my_key_pair_name)
          @base_key_dir = Pantry.root.join("security", "curve")
          @my_keys_file = @base_key_dir.join("#{my_key_pair_name}.yml")

          ensure_directory_structure
          check_or_generate_my_keys
        end

        # Check if the given client public key is known by this server or
        # not. Used solely by Servers
        def known_client?(client_public_key)
          @known_clients.include?(z85_encode(client_public_key))
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
          else
            generate_new_key_pair
          end
        end

        def load_current_key_pair
          keys = YAML.load_file(@my_keys_file)
          @public_key = keys["public_key"]
          @private_key = keys["private_key"]
          @server_public_key = keys["server_public_key"]
          @known_clients = keys["client_keys"] || []
        end

        def generate_new_key_pair
          @public_key, @private_key = ZMQ::Util.curve_keypair
          @known_clients = []

          File.open(@my_keys_file, "w+") do |f|
            f.write YAML.dump({
              "private_key" => @private_key,
              "public_key" => @public_key,
              "client_keys" => @known_clients
            })
          end
        end
      end

    end
  end
end
