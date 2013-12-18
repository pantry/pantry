module Pantry
  module Chef

    # Execute ChefSolo on the current box, returning STDOUT, STDERR, and status code.
    class RunChefSolo < Pantry::Command

      def self.command_type
        "Chef::ChefSolo"
      end

      def perform(message)
        begin
          stdout, stderr, status = Open3.capture3("chef-solo")
          [stdout, stderr, status.to_i]
        rescue Exception => e
          # Could not find the chef-solo binary
          ["", e.message, 1]
        end
      end

    end

  end
end
