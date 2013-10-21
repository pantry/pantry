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
    #
    # A client identity token can also be given via +identity+. If identity is provided
    # then that stream will be chosen above all others. Use this to send a message to
    # specific clients.
    class MessageFilter

      attr_reader :application, :environment, :roles, :identity

      def initialize(application: nil, environment: nil, roles: [], identity: nil)
        @application = application
        @environment = environment
        @roles       = roles
        @identity    = identity
      end

      # List out all communication streams this MessageFilter is configured to know about.
      def streams
        list = []
        base_stream = []

        if @identity
          list << @identity
        end

        if @application
          list << @application
          base_stream = [@application]
        end

        if @environment
          list << [base_stream, @environment].flatten.compact.join(".")
        end

        @roles.each do |role|
          list << [base_stream, @environment, role].flatten.compact.join(".")
        end

        list = list.flatten.compact
        list.empty? ? [""] : list
      end

      # Return the most specific stream that matches this MessageFilter.
      # +identity+ is chosen above all others.
      def stream
        if @identity
          @identity
        else
          [@application, @environment, @roles.first].compact.join(".")
        end
      end

      def ==(other)
        return false unless other
        return false unless other.is_a?(MessageFilter)

        self.application   == other.application &&
          self.environment == other.environment &&
          self.roles       == other.roles &&
          self.identity    == other.identity
      end

    end
  end
end
