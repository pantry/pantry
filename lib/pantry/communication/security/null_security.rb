module Pantry
  module Communication
    module Security

      # The no-security security strategy
      class NullSecurity

        def self.client
          new
        end

        def self.server
          new
        end

        def link_to(parent)
          # no-op
        end

        def configure_socket(socket)
          # no-op
        end

      end

    end
  end
end
