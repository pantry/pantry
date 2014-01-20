# Monkey Patch Celluloid::ZMQ to allow pass through
# of direct setsockopt calls, so we can configure sockets
# as we need to

module Celluloid
  module ZMQ
    class Socket
      def setsockopt(*args)
        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(*args)
          raise IOError, "couldn't set value: #{::ZMQ::Util.error_string}"
        end
      end
    end
  end
end

