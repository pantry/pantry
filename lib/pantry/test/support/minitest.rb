require 'minitest/autorun'

# Global helpers we're adding to Minitest
module PantryMinitestHelpers
  def before_setup
    Celluloid.init
    Pantry.reset_config!
  end
end

class Minitest::Test
  include PantryMinitestHelpers
end
