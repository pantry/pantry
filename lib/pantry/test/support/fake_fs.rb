gem 'fakefs'
require 'fakefs/safe'

# Hook up FakeFS into Minitest
class MiniTest::Test
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
