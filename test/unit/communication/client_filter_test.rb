require 'unit/test_helper'
require 'pantry/communication/client_filter'

describe Pantry::Communication::ClientFilter do

  describe "#streams" do
    it "returns empty string if no filters given" do
      filter = Pantry::Communication::ClientFilter.new({})
      assert_equal [""], filter.streams
    end

    it "takes a hash of filters and builds streams from them" do
      filter = Pantry::Communication::ClientFilter.new(
        identity:    "my_test_ident",
        application: "pantry",
        environment: "test",
        roles:       %w(db app)
      )

      expected_streams = [
        "my_test_ident",
        "pantry",
        "pantry.test",
        "pantry.test.db",
        "pantry.test.app",
      ]

      assert_equal expected_streams, filter.streams
    end

    it "handles environment and roles, no application" do
      filter = Pantry::Communication::ClientFilter.new(
        environment: "test",
        roles:       %w(db app)
      )

      expected_streams = [
        "test",
        "test.db",
        "test.app",
      ]

      assert_equal expected_streams, filter.streams
    end

    it "handles application and roles, no environment, properly" do
      filter = Pantry::Communication::ClientFilter.new(
        application: "pantry",
        roles:       %w(db app)
      )

      expected_streams = [
        "pantry",
        "pantry.db",
        "pantry.app",
      ]

      assert_equal expected_streams, filter.streams
    end

    it "handles just roles" do
      filter = Pantry::Communication::ClientFilter.new(
        roles:       %w(db app)
      )

      assert_equal ["db", "app"], filter.streams
    end
  end

  describe "#stream" do
    it "returns the most explicit stream matching filters given" do
      filter = Pantry::Communication::ClientFilter.new(
        application: "pantry",
        environment: "test",
        roles:       %w(db)
      )

      assert_equal "pantry.test.db", filter.stream
    end

    it "ignores environment if left out" do
      filter = Pantry::Communication::ClientFilter.new(
        application: "pantry",
        roles:       %w(db)
      )

      assert_equal "pantry.db", filter.stream
    end

    it "ignores application if left out" do
      filter = Pantry::Communication::ClientFilter.new(
        roles:       %w(db)
      )

      assert_equal "db", filter.stream
    end

    it "uses the client identity if given" do
      filter = Pantry::Communication::ClientFilter.new(
        identity: "12345.client",
        roles:    %w(app db)
      )

      assert_equal "12345.client", filter.stream
    end
  end

  describe "#equality" do
    it "return true on empty filters" do
      assert_equal(
        Pantry::Communication::ClientFilter.new,
        Pantry::Communication::ClientFilter.new
      )
    end

    it "returns true on matching all options" do
      assert_equal(
        Pantry::Communication::ClientFilter.new(
          application: "app", environment: "test", roles: %w(db)),
        Pantry::Communication::ClientFilter.new(
          application: "app", environment: "test", roles: %w(db))
      )
    end

    it "returns false if other is nil" do
      refute_equal(
        Pantry::Communication::ClientFilter.new,
        nil
      )
    end
  end

end