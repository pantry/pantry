require 'unit/test_helper'

describe Pantry::UI do

  it "outputs messages to stdout" do
    out, err = capture_io do
      Pantry::UI.new.say("This is cool")
    end

    assert_equal "This is cool\n", out
  end

  it "outputs arrays as tables to stdout" do
    out, err = capture_io do
      Pantry::UI.new.list(%w(1 2 3))
    end

    assert_equal "1\n2\n3\n", out
  end

end
