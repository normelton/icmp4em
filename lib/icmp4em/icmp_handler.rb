module ICMP4EM
  module IcmpHandler
    def initialize args = {}
      @manager = args[:manager]
    end

    def notify_readable
      data, host = @io.recvfrom(1500)
      icmp_data = data[20, data.length]
      
      begin
        @manager.handle_reply Packet.from_bytes(icmp_data)
      rescue ArgumentError
      end
    end

    def unbind
      @socket.close if @socket
    end
  end
end