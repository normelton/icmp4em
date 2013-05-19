module ICMP4EM
  module Proxy
    class Request
      include EM::Deferrable

      attr_accessor :source_ip
      attr_accessor :source_port
      attr_accessor :dest_ip
      attr_accessor :packet

      def self.from_bytes args = {}
        request = Request.new

        data = args[:data]
        address_length = data.unpack("n").first

        request.source_ip = args[:source_ip]
        request.source_port = args[:source_port]
        request.dest_ip = data[2,address_length]
        request.packet = Packet.from_bytes data[address_length + 2, data.length]

        request
      end

      def initialize args = {}
      end

      def to_bytes
        [@dest_ip.length].pack("n") + @dest_ip + @packet.to_bytes
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