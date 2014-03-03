# For actions that print out or use the console via
# Pantry.ui, these helpers mock out stdout/stderr to make it easy
# to grab what's printed and to inject keypresses
class MiniTest::Test
  def self.mock_ui!
    before do
      @mock_stdin = StringIO.new
      @mock_stdout = StringIO.new
      Pantry.reset_ui!
      Pantry.ui(@mock_stdin, @mock_stdout)
    end
  end

  # Return the strings added to stdout through the test
  def stdout
    @mock_stdout.string
  end

  # Get access to the mock of STDIN to add values
  def stdin
    @mock_stdin
  end
end
