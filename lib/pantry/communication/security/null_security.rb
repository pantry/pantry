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

      end

    end
  end
end
