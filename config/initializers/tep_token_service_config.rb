# TEP Token Service Configuration
# Ensures JWT keys are properly loaded and cached

module TepTokenServiceConfig
  def self.ensure_keys_loaded
    # Force keys to be loaded on app boot
    TepTokenService.private_key
    TepTokenService.public_key

    Rails.logger.info "TEP Token Service keys loaded successfully"
    Rails.logger.info "  JWT Issuer: #{TMCP.config[:jwt_issuer]}"
    Rails.logger.info "  JWT Key ID: #{TMCP.config[:jwt_key_id]}"
    Rails.logger.info "  JWT Algorithm: #{TMCP.config[:jwt_algorithm]}"
  end
end

# Load keys immediately after Rails boots
Rails.application.config.after_initialize do
  TepTokenServiceConfig.ensure_keys_loaded
end
