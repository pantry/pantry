# Some custom MiniTest matchers used throughout the system

class Minitest::Test

  # I don't like the refute_ syntax, sorry =/

  alias assert_not_nil refute_nil
  alias assert_not     refute

end