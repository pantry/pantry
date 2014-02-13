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

  describe "Progress bar" do

    it "allows starting a progress bar" do
      Pantry.ui.progress_start(100)

      assert_match /^Progress:/m, stdout
    end

    it "can increment the current progress bar" do
      meter = Pantry.ui.progress_start(100)
      Pantry.ui.progress_step(10)

      assert_equal 10, meter.progress
    end

    it "handles increments past the progress bar's total" do
      meter = Pantry.ui.progress_start(100)
      Pantry.ui.progress_step(110)

      assert_equal 100, meter.progress
    end

    it "finishes the current progress bar" do
      meter = Pantry.ui.progress_start(100)
      Pantry.ui.progress_finish

      assert_equal 100, meter.progress
    end

  end

end
