module ICMP4EM
  class Manager
    # The first 16 bits of the header data is unique to this particular ping process
    MAX_IDENTIFIER = 2**16 - 1

    # We use the next 12 bits as the request identifier, regardless of the retry ...
    MAX_SEQUENCE = 2**12 - 1

    # ... and the remaining 4 bits to identify the retry
    MAX_RETRIES = 2**4 - 1

    @pending_requests = {}
    @socket = nil

    attr_accessor :id
    attr_accessor :socket
    attr_accessor :timeout
    attr_accessor :retries

    def initialize args = {}
      @timeout = args[:timeout] || 1
      @retries = args[:retries] || 3
      @id = rand(MAX_IDENTIFIER)
      @pending_requests = {}
      @next_request_id = 0

      if args[:proxy]
        if args[:proxy].is_a?(String)
          proxy_host = args[:proxy].split(":")[0]
          proxy_port = args[:proxy].split(":")[1] || 63312
          @proxy_addr = Socket.pack_sockaddr_in(proxy_port, proxy_host)
        else
          @proxy_addr = Socket.pack_sockaddr_in(63312, "127.0.0.1")
        end

        @socket = Socket.new(Socket::PF_INET, Socket::SOCK_DGRAM)
        EventMachine.watch(@socket, UdpHandler, :manager => self) {|c| c.notify_readable = true}

      else
        @socket = Socket.new(Socket::PF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
        EventMachine.watch(@socket, IcmpHandler, :manager => self) {|c| c.notify_readable = true}
      end
    end

    def proxy_enabled?
      @proxy_addr
    end

    def ping host, args = {}
      while @pending_requests.include?(@next_request_id)
        @next_request_id += 1
        @next_request_id %= MAX_SEQUENCE
      end

      request = Request.new args.merge(:host => host, :manager => self, :id => @next_request_id)

      @pending_requests[request.id] = request

      request.callback do
        @pending_requests.delete request.id
      end

      request.errback do
        @pending_requests.delete request.id
      end

      request.send
      
      request
    end

    def handle_reply reply
      return unless reply.valid_checksum?
      return unless reply.is_reply?

      request = @pending_requests.delete(reply.request_id)
      return if request.nil?

      request.succeed
    end

    def send_packet args = {}
      begin
        if proxy_enabled?
          proxy_request = ICMP4EM::Proxy::Request.new
          proxy_request.dest_ip = args[:to]
          proxy_request.packet = args[:packet]

          @socket.send proxy_request.to_bytes, 0, @proxy_addr

        else
          sock_addr = Socket.pack_sockaddr_in(0, args[:to])
          @socket.send args[:packet].to_bytes, 0, sock_addr
        end
      rescue
        puts "Got exception #{$!}"
        fail $!
      end

    end
  end
end
