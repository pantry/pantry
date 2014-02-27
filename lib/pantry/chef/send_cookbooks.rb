module Pantry
  module Chef

    # Given a list of cookbooks and the Receivers waiting for them,
    # set up some senders to start sending the appropriate Cookbook files along.
    class SendCookbooks < Pantry::Command

      def perform(message)
        message.body.each do |(name, receiver_uuid, file_uuid)|
          server.send_file(
            Pantry.root.join("chef", "cookbook-cache", "#{name}.tgz"),
            receiver_uuid,
            file_uuid
          )
        end

        true
      end

    end

  end
end
