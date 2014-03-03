require 'pantry/test/unit'
gem 'mocha'
require 'mocha/mini_test'

# Swap these lines to turn on the logger in tests
Pantry.logger.disable!
#Pantry.config.log_level = :debug

class Minitest::Test
  def setup
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)
    clean_up_pantry_root
  end

  # Ensure Pantry.root is always clean for each test.
  def clean_up_pantry_root
    Dir["#{Pantry.root}/**/*"].each do |file|
      FileUtils.rm_rf file
    end
  end

  def fixture_path(file_path)
    File.join(File.dirname(__FILE__), "..", "fixtures", file_path)
  end
end
