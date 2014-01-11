module Pantry
  module Chef

    # Client syncs up it's local list of Chef Cookbooks with what the Server
    # says the Client should have.
    class SyncCookbooks < Pantry::Command

      command "chef:cookbooks:sync" do
        description "Update Clients with the cookbooks they should run"
      end

      def perform(message)
        cookbooks_to_download = ask_server_for_cookbook_list
        Pantry.logger.debug("[#{client.identity}] Downloading cookbooks #{cookbooks_to_download}")

        recievers = build_cookbook_receivers(cookbooks_to_download)
        send_receiver_information_to_server(recievers)
        wait_for_receivers_to_finish(recievers)
        true
      end

      protected

      class FileAndReceiverInfo
        include Forwardable

        attr_reader :name, :version

        def initialize(name, version, receiver_info)
          @name = name
          @version = version
          @receiver_info = receiver_info
        end

        def method_missing(*args, &block)
          @receiver_info.send(*args, &block)
        end
      end

      def ask_server_for_cookbook_list
        send_request!(Pantry::Chef::ListCookbooks.new.to_message).body
      end

      def build_cookbook_receivers(cookbook_list)
        cookbook_list.map do |(name, version, size, checksum)|
          receive_info = FileAndReceiverInfo.new(name, version, client.receive_file(size, checksum))
          receive_info.on_complete(&unpack_received_file(receive_info))
          receive_info
        end
      end

      def unpack_received_file(receiver_info)
        lambda do
          stdout, stderr = Open3.capture2e(
            "tar",
            "-xzC", Pantry.root.join("chef", "cookbooks").to_s,
            "-f", receiver_info.uploaded_path
          )

          Pantry.logger.debug("[#{client.identity}] Unpack cookbook #{stdout.inspect}, #{stderr.inspect}")
        end
      end

      def send_receiver_information_to_server(receivers)
        download_message = Pantry::Chef::SendCookbooks.new.to_message

        receivers.each do |receiver_info|
          download_message << [
            receiver_info.name,
            receiver_info.version,
            receiver_info.receiver_identity,
            receiver_info.uuid
          ]
        end

        if receivers.any?
          send_request(download_message)
        end
      end

      def wait_for_receivers_to_finish(receivers)
        receivers.each do |receive_info|
          receive_info.wait_for_finish
        end
      end

    end

  end
end
