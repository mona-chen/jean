# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load official mini-apps from YAML configuration
puts "Loading official mini-apps from config/mini_apps.yml..."

synced_count = MiniAppYamlLoader.sync_mini_apps

if synced_count > 0
  puts "✅ Successfully loaded #{synced_count} official mini-apps from YAML config"
else
  puts "⚠️  No mini-apps were loaded. Check config/mini_apps.yml exists and is valid."
end

# Approve official mini-apps (creates OAuth applications)
puts "\nApproving official mini-apps..."

approved_count = MiniAppYamlLoader.approve_official_mini_apps

if approved_count > 0
  puts "✅ Successfully approved #{approved_count} official mini-apps"
  puts "   OAuth applications created for all approved mini-apps"
else
  puts "⚠️  No mini-apps were approved. Check the YAML config and database."
end

puts "\n🎉 Database seeding complete!"
puts "Run 'rails db:seed' to ensure these are created in your database."
