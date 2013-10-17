module Pantry
  module Communication
    class MessageFilter

      def initialize(application: nil, environment: nil, roles: [])
        @application = application
        @environment = environment
        @roles       = roles
      end

      def streams
        base_stream = @application ? [@application] : []
        list = base_stream.clone

        if @environment
          list << [base_stream, @environment].flatten.compact.join(".")
        end

        @roles.each do |role|
          list << [base_stream, @environment, role].flatten.compact.join(".")
        end

        list = list.flatten.compact
        list.empty? ? [""] : list
      end

      def stream
        [@application, @environment, @roles.first].compact.join(".")
      end

    end
  end
end
