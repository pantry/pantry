require 'unit/test_helper'
require 'pantry/communication/message_filter'

describe Pantry::Communication::MessageFilter do

  describe "#streams" do
    it "returns empty string if no filters given" do
      filter = Pantry::Communication::MessageFilter.new({})
      assert_equal [""], filter.streams
    end

    it "takes a hash of filters and builds streams from them" do
      filter = Pantry::Communication::MessageFilter.new(
        application: "pantry",
        environment: "test",
        roles:       %w(db app)
      )

      expected_streams = [
        "pantry",
        "pantry.test",
        "pantry.test.db",
        "pantry.test.app",
      ]

      assert_equal expected_streams, filter.streams
    end

    it "handles environment and roles, no application" do
      filter = Pantry::Communication::MessageFilter.new(
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
      filter = Pantry::Communication::MessageFilter.new(
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
      filter = Pantry::Communication::MessageFilter.new(
        roles:       %w(db app)
      )

      assert_equal ["db", "app"], filter.streams
    end
  end

  describe "#stream" do
    it "returns the most explicit stream matching filters given" do
      filter = Pantry::Communication::MessageFilter.new(
        application: "pantry",
        environment: "test",
        roles:       %w(db)
      )

      assert_equal "pantry.test.db", filter.stream
    end

    it "ignores environment if left out" do
      filter = Pantry::Communication::MessageFilter.new(
        application: "pantry",
        roles:       %w(db)
      )

      assert_equal "pantry.db", filter.stream
    end

    it "ignores application if left out" do
      filter = Pantry::Communication::MessageFilter.new(
        roles:       %w(db)
      )

      assert_equal "db", filter.stream
    end
  end

end
