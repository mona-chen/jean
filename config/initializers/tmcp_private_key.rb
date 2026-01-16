# frozen_string_literal: true

# Load TMCP private key from file for JWT signing
# This keeps sensitive keys out of environment variables and docker-compose.yml

require "fileutils"

module TmcpPrivateKeyLoader
  KEY_PATH = ENV.fetch("TMCP_PRIVATE_KEY_FILE", "/run/secrets/tmcp_private_key")

  class << self
    def load
      return if ENV["TMCP_PRIVATE_KEY"].present?

      key_content = nil

      if File.exist?(KEY_PATH)
        key_content = File.read(KEY_PATH).strip
        Rails.logger.info "Loaded TMCP private key from #{KEY_PATH}"
      elsif File.exist?(File.join(Rails.root, "secrets", "tmcp_private_key.txt"))
        key_content = File.read(File.join(Rails.root, "secrets", "tmcp_private_key.txt")).strip
        Rails.logger.info "Loaded TMCP private key from local secrets file"
      else
        Rails.logger.warn "TMCP private key file not found at #{KEY_PATH} or local secrets"
      end

      ENV["TMCP_PRIVATE_KEY"] = key_content if key_content
    end
  end
end

# Load when Rails boots
TmcpPrivateKeyLoader.load
