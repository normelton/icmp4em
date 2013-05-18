require "spec_helpers.rb"

describe "When pinging something that should answer" do
  it "should handle the response" do
    request = ICMP4EM::Manager.new.ping "127.0.0.1"
    @pending_requests << request

    request.callback do
      # Success
    end

    request.errback do
      fail "Should have called callback"
    end

    request.expect(&p)
  end
end

describe "Whening pinging something that should not answer" do
  it "should trigger errback" do
    request = ICMP4EM::Manager.new.ping "127.250.250.250"
    @pending_requests << request

    request.callback do
      fail "Should have called errback"
    end

    request.errback do |error|
      error.should be_a(ICMP4EM::Timeout)
      EventMachine.stop
    end
  end
end