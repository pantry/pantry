# Monkey Patch the new curve_keypair method until
# a new release of ffi-rzmq is out.
module ZMQ
  class Util
    def self.curve_keypair
      public_key = FFI::MemoryPointer.from_string(' ' * 41)
      private_key = FFI::MemoryPointer.from_string(' ' * 41)
      rc = LibZMQ.zmq_curve_keypair public_key, private_key

      if rc < 0
        raise NotSupportedError.new "zmq_curve_keypair" , rc, ZMQ::Util.errno,
          "Rebuild zeromq with libsodium to enable CURVE security options."
      end

      [public_key.read_string, private_key.read_string]
    end
  end
end
