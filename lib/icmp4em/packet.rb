module ICMP4EM
  class Packet
    ICMP_CODE           = 0
    ICMP_ECHO_REQUEST   = 8
    ICMP_ECHO_REPLY     = 0

    attr_accessor :type
    attr_accessor :code
    attr_accessor :checksum
    attr_accessor :manager_id
    attr_accessor :request_id
    attr_accessor :retry_id
    attr_accessor :payload

    def self.from_bytes data
      raise ArgumentError, "Must provide at least eight bytes in order to craft an ICMP packet" unless data.length >= 8

      packet = Packet.new
      fields = data.unpack("C2 n3 A*")

      packet.type = fields.shift
      packet.code = fields.shift
      packet.checksum = fields.shift
      packet.manager_id = fields.shift

      sequence = fields.shift
      packet.request_id = sequence >> 4
      packet.retry_id = sequence & (2**4 - 1)

      packet.payload = fields.shift

      packet
    end

    def initialize args = {}
      @type         = args[:type] || ICMP_ECHO_REQUEST
      @code         = args[:code] || ICMP_CODE
      @manager_id   = args[:manager_id]
      @request_id   = args[:request_id]
      @retry_id     = args[:retry_id]

      if args[:payload].nil?
        @payload = ""
      elsif args[:payload].is_a? Integer
        @payload = "A" * args[:payload]
      else
        @payload = args[:payload]
      end
    end

    def is_request?
      @type == ICMP_ECHO_REQUEST
    end

    def is_reply?
      @type == ICMP_ECHO_REPLY
    end

    def valid_checksum?
      @checksum == compute_checksum
    end

    def to_bytes
      [@type, @code, compute_checksum, @manager_id, compute_sequence, @payload].pack("C2 n3 A*")
    end

    private

    # Perform a checksum on the message.  This is the sum of all the short
    # words and it folds the high order bits into the low order bits.
    # This method was stolen directly from the old icmp4em - normelton
    # ... which was stolen directly from net-ping - yaki

    def compute_sequence
      (@request_id << 4) + @retry_id
    end      

    def compute_checksum
      msg = [@type, @code, 0, @manager_id, compute_sequence, @payload].pack("C2 n3 A*")

      length    = msg.length
      num_short = length / 2
      check     = 0

      msg.unpack("n#{num_short}").each do |short|
        check += short
      end

      if length % 2 > 0
        check += msg[length-1, 1].unpack('C').first << 8
      end

      check = (check >> 16) + (check & 0xffff)
      return (~((check >> 16) + check) & 0xffff)
    end

  end
end