require 'minitest/autorun'
require 'mocha/setup'
require 'support/matchers'
require 'celluloid/test'
require 'fakefs/safe'

require 'pantry'

Pantry.logger.disable!

class Minitest::Test

  def setup
    Celluloid.init
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)
  end

  def teardown
    Dir["#{Pantry.root}/*"].each do |file|
      FileUtils.rm_rf file
    end
  end

  def fixture_path(file_path)
    File.join(File.dirname(__FILE__), "..", "fixtures", file_path)
  end

  def self.fake_fs!
    before do
      FakeFS.activate!
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end
  end

end

# Minitest uses Tempfiles for figuring out more complicated diffs
# This causes FakeFS to explode, so make sure this is run without FakeFS
# enabled.
module MiniTest
  module Assertions
    alias :actual_diff :diff

    def diff exp, act
      FakeFS.without do
        actual_diff exp, act
      end
    end
  end
end
