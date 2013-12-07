require 'minitest/autorun'
require 'mocha/setup'
require 'support/matchers'
require 'celluloid/test'

require 'pantry'

Pantry.logger.disable!

class Minitest::Test

  def setup
    Celluloid.init
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)
  end

  def teardown
    Dir["#{Pantry.config.data_dir}/*"].each do |file|
      FileUtils.rm_rf file
    end
  end

end
