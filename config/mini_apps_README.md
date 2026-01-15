# Official Mini-Apps Configuration

This directory contains the configuration for official mini-apps that are automatically created and managed by the TMCP Server.

## Overview

Official mini-apps are defined in `config/mini_apps.yml` and are automatically loaded during database seeding. This allows you to:

- Easily add/remove/modify official mini-apps
- Version control mini-app configurations
- Deploy mini-app updates without code changes
- Maintain consistent mini-app definitions across environments

## File Structure

```
config/
└── mini_apps.yml          # Official mini-apps configuration
```

## Configuration Format

The YAML file contains an `official_mini_apps` array with mini-app definitions:

```yaml
official_mini_apps:
  - app_id: ma_tweenpay
    name: TweenPay
    description: Official Tween wallet and payment application
    version: "1.0.0"
    classification: official
    developer_name: Tween IM
    manifest:
      permissions: [...]
      scopes: [...]
      entry_url: "..."
      redirect_uris: [...]
      webhook_url: "..."
      icon_url: "..."
      categories: [...]
      features: [...]
```

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `app_id` | string | Unique mini-app ID (ma_*) | `ma_tweenpay` |
| `name` | string | Display name | `TweenPay` |
| `description` | string | Full description | `Official Tween wallet...` |
| `version` | string | Version number | `1.0.0` |
| `classification` | string | Must be `official` | `official` |
| `developer_name` | string | Developer/organization | `Tween IM` |
| `manifest` | object | Mini-app manifest (see below) | |

### Manifest Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `permissions` | array | Internal permissions | Yes |
| `scopes` | array | OAuth scopes | Yes |
| `entry_url` | string | Mini-app URL | Yes |
| `redirect_uris` | array | OAuth redirect URIs | Yes |
| `webhook_url` | string | Webhook endpoint | No |
| `icon_url` | string | Icon URL | No |
| `categories` | array | App categories | No |
| `features` | array | Feature list | No |

## Usage

### Load/Update Mini-Apps from YAML

```bash
# Load mini-apps from YAML (creates/updates in database)
rails mini_apps:load_from_yaml

# Same as above (alias)
rails mini_apps:seed_official
```

### Approve Official Mini-Apps

```bash
# Approve all official mini-apps (creates OAuth applications)
rails mini_apps:approve_official_from_yaml
```

### Database Seeding

The `db:seed` command automatically:

1. Loads mini-apps from `config/mini_apps.yml`
2. Creates/updates them in the database
3. Approves official mini-apps
4. Creates OAuth applications

```bash
rails db:seed
```

### Manage Mini-Apps

```bash
# List all mini-apps
rails mini_apps:list

# Show specific mini-app details
rails mini_apps:show[ma_tweenpay]

# Approve individual mini-app
rails mini_apps:approve[ma_tweenpay]
```

## Adding New Official Mini-Apps

1. **Edit `config/mini_apps.yml`**:
   ```yaml
   official_mini_apps:
     # existing apps...
     - app_id: ma_newapp
       name: New App
       description: Description of new app
       version: "1.0.0"
       classification: official
       developer_name: Tween IM
       manifest:
         permissions: ["user_read", "storage_write"]
         scopes: ["user:read", "storage:write"]
         entry_url: "https://miniapp.tween.im/newapp/"
         redirect_uris: ["https://miniapp.tween.im/newapp/callback"]
         # ... other fields
   ```

2. **Update the database**:
   ```bash
   rails mini_apps:load_from_yaml
   ```

3. **Commit the changes**:
   ```bash
   git add config/mini_apps.yml
   git commit -m "Add new official mini-app: New App"
   ```

## Modifying Existing Mini-Apps

1. **Edit the YAML file** with your changes
2. **Update the database**:
   ```bash
   rails mini_apps:load_from_yaml
   ```
3. **The system will update existing mini-apps** with new configurations

## Removing Mini-Apps

⚠️ **Warning**: Removing a mini-app from the YAML file will NOT automatically remove it from the database. You must manually handle cleanup.

To properly remove a mini-app:

1. **Remove from YAML file**
2. **Manually delete from database** (if desired):
   ```ruby
   MiniApp.find_by(app_id: "ma_oldapp").destroy
   ```
3. **Remove OAuth application** (if approved):
   ```ruby
   Doorkeeper::Application.find_by(uid: "ma_oldapp").destroy
   ```

## Deployment

Official mini-apps are automatically deployed with:

```bash
# During deployment
rails db:seed  # Loads from YAML and approves official apps

# Or manually
rails mini_apps:load_from_yaml
rails mini_apps:approve_official_from_yaml
```

## Validation

The system validates:

- **App ID format**: Must start with `ma_` followed by alphanumeric characters
- **URLs**: Must be HTTPS (for production)
- **Scopes**: Must match available TMCP scopes
- **Manifest structure**: Required fields must be present

## Examples

### Adding a Simple Mini-App

```yaml
- app_id: ma_weather
  name: TweenWeather
  description: Weather information mini-app
  version: "1.0.0"
  classification: official
  developer_name: Tween IM
  manifest:
    permissions: ["user_read", "storage_read"]
    scopes: ["user:read", "storage:read"]
    entry_url: "https://miniapp.tween.im/weather/"
    redirect_uris: ["https://miniapp.tween.im/weather/callback"]
    categories: ["utilities", "information"]
```

### Adding a Payment Mini-App

```yaml
- app_id: ma_payments
  name: TweenPayments
  description: Payment processing mini-app
  version: "1.0.0"
  classification: official
  developer_name: Tween IM
  manifest:
    permissions: ["wallet_pay", "user_read", "storage_write"]
    scopes: ["wallet:pay", "user:read", "storage:write"]
    entry_url: "https://miniapp.tween.im/payments/"
    redirect_uris: ["https://miniapp.tween.im/payments/callback"]
    webhook_url: "https://api.tween.im/webhooks/payments"
    categories: ["finance", "payments"]
    features: ["payment_processing", "transaction_history", "refunds"]
```

## Troubleshooting

### Mini-App Not Loading

Check the Rails logs:
```bash
tail -f log/production.log
```

Look for YAML parsing errors or validation failures.

### OAuth Application Not Created

Ensure the mini-app is approved:
```bash
rails mini_apps:show[ma_appid]
# Check status field
```

### Changes Not Applied

After editing YAML, run:
```bash
rails mini_apps:load_from_yaml
```

## Related Files

- `config/mini_apps.yml` - This configuration file
- `app/services/mini_app_yaml_loader.rb` - YAML loading service
- `lib/tasks/mini_apps.rake` - Management rake tasks
- `db/seeds.rb` - Database seeding script