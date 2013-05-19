module ICMP4EM
  module Proxy
    module UdpHandler
      def initialize args
        @icmp_socket      = args[:icmp_socket]
        @pending_requests = args[:pending_requests]

        log "Listening for incoming requests"
      end

      def log msg
        puts "[#{Time.now}] #{msg}" if $debug
      end

      def receive_data data
        source_port, source_ip = Socket.unpack_sockaddr_in(get_peername)

        log "Received incoming request from #{source_ip}:#{source_port}"

        begin
          request = Request.from_bytes :source_ip => source_ip, :source_port => source_port, :data => data
        rescue ArgumentError
          log "  Received error - #{$!}"
          return
        end

        unless request.packet.is_request?
          log "  Incoming packet is not an ICMP request"
          return
        end

        log "  Key = #{request.key_string}"
        log "  Sending to #{request.dest_ip}"

        begin
          request.send :socket => @icmp_socket
        rescue
          log "  Got exception while sending packet #{request.dest_ip} #{$!}"
          return
        end

        request.timeout(30)

        request.callback do |packet|
          log "  Got reply for request #{request.key_string}"
          log "  Sending reply back to #{source_ip}:#{source_port}"
          send_datagram packet.to_bytes, source_ip, source_port
          @pending_requests.delete request.key
        end

        request.errback do
          log "Request #{request.key_string} has timed out"
          @pending_requests.delete request.key
        end

        @pending_requests[request.key] = request
      end
    end
  end
end