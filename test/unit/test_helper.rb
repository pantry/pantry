require 'minitest/autorun'
require 'mocha/setup'
require 'support/matchers'
require 'celluloid/test'

require 'pantry'

Pantry.logger(nil)


class Minitest::Test

  def setup
    Celluloid.init
  end

  def with_custom_config
    old_config = Pantry.config.clone
    yield
  ensure
    Pantry.class_variable_set("@@config", old_config)
  end

end
