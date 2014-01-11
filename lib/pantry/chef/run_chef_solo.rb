module Pantry
  module Chef

    # Execute ChefSolo on the current box, returning STDOUT, STDERR, and status code.
    class RunChefSolo < Pantry::Command

      def perform(message)
        begin
          solo_rb = Pantry.root.join("etc", "chef", "solo.rb")
          stdout, stderr, status = Open3.capture3("chef-solo --config #{solo_rb}")
          [stdout, stderr, status.to_i]
        rescue Exception => e
          # Could not find the chef-solo binary
          ["", e.message, 1]
        end
      end

    end

  end
end
