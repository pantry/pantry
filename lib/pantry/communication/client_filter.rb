module Pantry
  module Communication

    # ClientFilter handles and manages building filters that map configuration values
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
    class ClientFilter

      attr_reader :application, :environment, :roles, :identity

      def initialize(application: nil, environment: nil, roles: [], identity: nil)
        @application = application
        @environment = environment
        @roles       = roles || []
        @identity    = identity
      end

      # List out all communication streams this ClientFilter is configured to know about.
      def streams(skip_identity = false)
        list = []
        base_stream = []

        if @identity && !skip_identity
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

      # Return the most specific stream that matches this ClientFilter.
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
        return false unless other.is_a?(ClientFilter)

        self.application   == other.application &&
          self.environment == other.environment &&
          self.roles       == other.roles &&
          self.identity    == other.identity
      end

      # Will this filter match on the given stream?
      def matches?(test_stream)
        self.streams.any? do |stream|
          stream.start_with?(test_stream)
        end
      end

      # A filter includes another filter if the other filter matches.
      # This does not look at identities.
      def includes?(filter)
        return true if self == filter
        return true if streams == [""]

        my_stream =    Set.new(streams(:skip_identity))
        other_stream = Set.new(filter.streams(:skip_identity))

        my_stream.subset?(other_stream)
      end

      def to_hash
        {
          application: @application,
          environment: @environment,
          roles:       @roles,
          identity:    @identity
        }
      end

    end
  end
end
