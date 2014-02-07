require 'unit/test_helper'

describe Pantry::UI do

  mock_ui!

  it "outputs messages to stdout" do
    Pantry.ui.say("This is cool")
    assert_equal "This is cool\n", stdout
  end

  it "outputs arrays as tables to stdout" do
    Pantry.ui.list(%w(1 2 3))
    assert_equal "1\n2\n3\n", stdout
  end

  it "asks a question, waits for keypress and comes back" do
    stdin << "\n"
    stdin.rewind

    result = Pantry.ui.continue?("This is a message")

    assert_match /This is a message/, stdout
    assert result, "Default enter should have been a true message"
  end

end
