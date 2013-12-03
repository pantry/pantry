require 'minitest/autorun'
require 'mocha/setup'
require 'support/matchers'
require 'celluloid/test'

require 'pantry'

Pantry.logger.disable!

class Minitest::Test

  def setup
    Celluloid.init
  end

end
