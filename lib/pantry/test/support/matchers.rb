# Some custom MiniTest matchers used throughout the system

module Minitest::Assertions

  # I don't like the refute_ syntax, sorry =/

  alias assert_not_nil   refute_nil
  alias assert_not       refute
  alias assert_false     refute
  alias assert_not_equal refute_equal
  alias assert_no_match  refute_match

end
