require 'unit/test_helper'

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

  describe "#includes?" do
    it "returns true if the two filters are equal" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))

      assert f2.includes?(f1), "f1's match set was not included in f2's match set"
    end

    it "returns true if the most specific stream" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new(application: "app")

      assert f2.includes?(f1), "app should have included app.test.db"
    end

    it "handles multiple roles" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", roles: %w(db web))
      f2 = Pantry::Communication::ClientFilter.new(application: "app", roles: %w(web))

      assert f2.includes?(f1), "app.web should have included app.test.web / app.test.db"
    end

    it "returns false if application doesn't match" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new(
        application: "app2", environment: "test", roles: %w(db))

      assert_false f2.includes?(f1), "f1's match set was included in f2's match set"
    end

    it "returns false if environment doesn't match" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "dev", roles: %w(db))

      assert_false f2.includes?(f1), "f1's match set was included in f2's match set"
    end

    it "returns false if roles doesn't match" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(app))
      f2 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))

      assert_false f2.includes?(f1), "f1's match set was included in f2's match set"
    end

    it "returns false if environments are given in one but not the other" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new(
        application: "app", roles: %w(db))

      assert_false f2.includes?(f1), "f1's match set was included in f2's match set"
    end

    it "returns true if we are the empty set (match all)" do
      f1 = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db))
      f2 = Pantry::Communication::ClientFilter.new()

      assert f2.includes?(f1), "f1 was not included in f2's all client match"
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the filter" do
      filter = Pantry::Communication::ClientFilter.new(
        application: "app", environment: "test", roles: %w(db), identity: "test"
      )

      assert_equal(
        {application: "app", environment: "test", roles: %w(db), identity: "test"},
        filter.to_hash
      )
    end
  end

end
