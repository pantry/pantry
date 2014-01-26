require 'support/minitest'
require 'mocha/setup'
require 'support/matchers'
require 'celluloid/test'
require 'fakefs/safe'

require 'pantry'

Pantry.logger.disable!
#Pantry.config.log_level = :debug

class Minitest::Test

  def setup
    Celluloid.init
    Pantry.reset_config!
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)
  end

  def teardown
    clean_up_pantry_root
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
module Minitest
  module Assertions
    alias :actual_diff :diff

    def diff exp, act
      FakeFS.without do
        actual_diff exp, act
      end
    end
  end
end
