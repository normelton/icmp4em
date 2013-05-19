module ICMP4EM
  module UdpHandler
    def initialize args = {}
      @manager = args[:manager]
    end

    def notify_readable
      data, host = @io.recvfrom(1500)
      
      begin
        @manager.handle_reply Packet.from_bytes(data)
      rescue ArgumentError
      end
    end

    def unbind
      @socket.close if @socket
    end
  end
end