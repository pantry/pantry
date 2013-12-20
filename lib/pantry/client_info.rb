module Pantry

  # Simple class to keep track of a given client's identifying information
  class ClientInfo
    attr_reader :application

    attr_reader :environment

    attr_reader :roles

    # The above gets packaged into a ClientFilter for use elsewhere
    attr_reader :filter

    # This client's current identity. By default a client's identity is it's `hostname`,
    # but a specific one can be given. These identities should be unique across the set
    # of clients connecting to a single Pantry Server, behavior of multiple clients with
    # the same identity is currently undefined.
    attr_reader :identity

    def initialize(application: nil, environment: nil, roles: [], identity: nil)
      @application = application
      @environment = environment
      @roles       = roles
      @identity    = identity

      @filter = Pantry::Communication::ClientFilter.new(
        application: @application,
        environment: @environment,
        roles:       @roles,
        identity:    @identity
      )
    end
  end
end
