module ICMP4EM
  module Proxy
    module IcmpHandler
      def initialize args = {}
        @pending_requests = args[:pending_requests]
      end

      def log msg
        puts "[#{Time.now}] #{msg}" if $debug
      end

      def notify_readable
        data, host = @io.recvfrom(1500)
        icmp_data = data[20, data.length]
        
        log "Received ICMP response from #{host.ip_address}"

        begin
          packet = Packet.from_bytes(icmp_data)
        rescue ArgumentError
          log "  Got exception while parsing packet: #{$!}"
          return
        end

        log "  Key = #{packet.key_string}"

        request = @pending_requests.delete(packet.key)

        if request.nil?
          log "  Unexpected packet, dropping"
          return
        end

        request.succeed packet
      end

      def unbind
        @socket.close if @socket
      end
      
    end
  end
end