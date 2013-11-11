module Pantry
  module Commands

    # Execute ChefSolo on the current box, returning STDOUT, STDERR, and status code.
    class RunChefSolo < Command

      def perform
        stdout, stderr, status = Open3.capture3("chef-solo")
        [stdout, stderr, status.to_i]
      end

    end

  end
end
