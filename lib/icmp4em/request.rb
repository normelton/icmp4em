module ICMP4EM
  class Request
    include EM::Deferrable

    attr_reader :id

    def initialize args = {}
      @host         = args[:host]
      @manager      = args[:manager]
      @id           = args[:id]
      @max_retries  = args[:retries] || @manager.retries
      @timeout      = args[:timeout] || @manager.timeout

      @retry_id = 0
      @timeout_timer = nil

      callback do
        @timeout_timer.cancel
      end
      
      errback do
        @timeout_timer.cancel
      end      

      send
    end

    def send
      @timeout_timer.cancel if @timeout_timer.is_a?(EventMachine::Timer)

      @timeout_timer = EventMachine::Timer.new(@timeout) do
        if @max_retries > @retry_id
          send
          @retry_id += 1
        else
          fail Timeout.new
        end
      end

      begin
        sock_addr = Socket.pack_sockaddr_in(0, @host)
        packet = Packet.new(:type => Packet::ICMP_ECHO_REQUEST, :manager_id => @manager.id, :request_id => @id, :retry_id => @retry_id)
        @manager.socket.send packet.to_bytes, 0, sock_addr
      rescue
        puts "Got exception #{$!}"
        fail $!
      end
    end
  end
end