require 'minitest/autorun'

# Global helpers we're adding to Minitest

class Minitest::Test

  def clean_up_pantry_root
    Dir["#{Pantry.root}/**/*"].each do |file|
      FileUtils.rm_rf file
    end
  end

  def fixture_path(file_path)
    File.join(File.dirname(__FILE__), "..", "fixtures", file_path)
  end

end
