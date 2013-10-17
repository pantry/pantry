module Pantry
  module Communication

    # MessageFilter handles and manages building filters that map configuration values
    # to 0MQ stream names. A message stream is a period-delimited string that works
    # with 0MQ's Subscription prefix matcher, allowing Clients to choose which messages
    # they want to receive. Streams are built to enable tiered delivery capability.
    #
    # For example, a Client with the application 'pantry' and roles 'app' and 'db' will
    # subscribe to the following streams:
    #
    #   pantry
    #   pantry.app
    #   pantry.db
    #
    # Similarly to differentiate between environments, the environment is added inbetween
    # the application and the role:
    #
    #   pantry
    #   pantry.production
    #   pantry.production.app
    #   pantry.production.db
    #
    # This class is also used to when sending messages, to choose which specific stream
    # (e.g. the deepest buildable) to send a given message down.
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
