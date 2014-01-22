module Pantry
  module Communication
    module Security

      class MissingKeyError < Exception; end

      # CurveKeyStore manages the storage, reading, and writing of all
      # Curve-related key-pairs.
      #
      # All keys are stored under Pantry.root/security/curve
      class CurveKeyStore

        attr_reader :public_key, :private_key

        def initialize(my_key_pair_name)
          @base_key_dir = Pantry.root.join("security", "curve")
          @my_keys_file = @base_key_dir.join("#{my_key_pair_name}.yml")

          ensure_directory_structure
          check_or_generate_my_keys
        end

        # Read the contents of a given file expected to be in the key store
        # If the file does not exist an error will be raised
        def get(key_file)
          key_file_path = @base_key_dir.join(key_file)

          unless File.exists?(key_file_path)
            raise MissingKeyError,
              "No key file found, expected one at #{key_file_path}"
          end

          File.read(key_file_path).strip
        end

        protected

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
        end

        def generate_new_key_pair
          @public_key, @private_key = ZMQ::Util.curve_keypair

          File.open(@my_keys_file, "w+") do |f|
            f.write YAML.dump({"private_key" => @private_key, "public_key" => @public_key})
          end
        end
      end

    end
  end
end
