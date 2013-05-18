require "icmp4em"

class ICMP4EM::Request
  def expect &block
    self.callback &block
    self.errback {|error| fail error}

    self.callback { EM.stop }
    self.errback  { EM.stop }
  end
end

RSpec.configure do |config|
  config.around :each do |spec|
    EM.run do
      @pending_requests = []

      EM.error_handler do |error|
        fail error
      end

      spec.run

      @pending_requests.each do |request|
        request.callback do
          @pending_requests.delete request
          EM.stop if @pending_requests.empty?
        end

        request.errback do
          @pending_requests.delete request
          EM.stop if @pending_requests.empty?
        end
      end

      EM.stop if @pending_requests.empty?
    end
  end
end