module ICMP4EM
  module Proxy
    class Request
      include EM::Deferrable

      attr_reader :source_ip
      attr_reader :source_port
      attr_reader :dest_ip
      attr_reader :packet

      def initialize args = {}
        data = args[:data]

        @source_ip = args[:source_ip]
        @source_port = args[:source_port]

        address_length = data.unpack("n").first
        @dest_ip = data[2,address_length]

        @packet = Packet.from_bytes data[address_length + 2, data.length]

        raise ArgumentError, "Did not receive an ICMP request" unless @packet.is_request?
      end

      def key
        @packet.key
      end

      def key_string
        key.unpack("H*").first
      end

      def send args = {}
        sock_addr = Socket.pack_sockaddr_in(0, @dest_ip)
        args[:socket].send @packet.to_bytes, 0, sock_addr
      end
    end
  end
end