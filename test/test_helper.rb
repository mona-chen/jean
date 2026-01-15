ENV["RAILS_ENV"] ||= "test"

# Load TMCP private key BEFORE Rails to ensure consistent key loading
TMCP_PRIVATE_KEY_PATH = File.join(__dir__, "../secrets/tmcp_private_key.txt")
TMCP_PRIVATE_KEY_VALUE = nil
unless defined?(TMCP_PRIVATE_KEY_VALUE)
  if File.exist?(TMCP_PRIVATE_KEY_PATH)
    TMCP_PRIVATE_KEY_VALUE = File.read(TMCP_PRIVATE_KEY_PATH).strip
    ENV["TMCP_PRIVATE_KEY"] = TMCP_PRIVATE_KEY_VALUE
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "minitest"

# Allow real requests to MAS for integration tests
WebMock.allow_net_connect!

# Pre-load the private key before tests start
TepTokenService.reset_keys!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Enable sessions for integration tests
  include ActionDispatch::TestProcess # Disabled for compatibility

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  setup do
    TepTokenService.reset_keys!

    # Set up MAS client credentials for tests
    ENV["MAS_CLIENT_ID"] ||= "GARMJ92HAZ0EBKRSASCWAAGXSA"
    ENV["MAS_CLIENT_SECRET"] ||= "pF/Y9eiJXTHASLFNPOIzXiym0E9o1J7o5+UsHONumS0="
    ENV["MAS_URL"] ||= "http://docker:8080"
    ENV["MAS_TOKEN_URL"] ||= "http://docker:8080/oauth2/token"
    ENV["MAS_INTROSPECTION_URL"] ||= "http://docker:8080/oauth2/introspect"
    ENV["MAS_REVOCATION_URL"] ||= "http://docker:8080/oauth2/revoke"
  end

  teardown do
    # Clean up environment variables that might affect other tests
    %w[MATRIX_ACCESS_TOKEN MATRIX_API_URL MAS_CLIENT_ID MAS_CLIENT_SECRET MAS_URL MAS_TOKEN_URL MAS_INTROSPECTION_URL MAS_REVOCATION_URL].each do |key|
      ENV.delete(key)
    end
    TepTokenService.reset_keys!
  end
end
