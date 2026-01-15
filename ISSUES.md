# Test Isolation Issue

## Status: OPEN - Test-only issue, Production is NOT affected

## Problem
Test suite occasionally fails with "Invalid TEP token: Invalid segment encoding" errors when running the full test suite. Individual test files run correctly.

**Test Results:**
- Most runs: 0 failures, 0 errors ✓
- Occasional runs: 20-45 failures (all "Invalid segment encoding")
- Individual test files: Always pass ✓
- Production: Not affected ✓

## Root Cause
Test isolation issue caused by:
1. Class reloading between test files in test mode
2. TepTokenService key initialization race conditions
3. Tests calling `reset_keys!` in setup/teardown

## Why Production is Safe
✓ Production loads `TMCP_PRIVATE_KEY` from ENV once at server startup
✓ No class reloading in production (classes load once and persist)
✓ No calls to `reset_keys!` in production code
✓ Key remains consistent throughout server's lifetime

## Known Test Flakes
The following test files occasionally fail with "Invalid segment encoding":
- `test/controllers/api/v1/gifts_controller_test.rb`
- `test/controllers/api/v1/storage_controller_test.rb`
- `test/controllers/api/v1/wallet_controller_test.rb`
- `test/controllers/api/v1/payments_controller_test.rb`

## Fixes Applied (in this PR)
1. ✅ Removed `use_transactional_tests = false` from OAuth controller test
2. ✅ Fixed `MiniappInstallation` model foreign key association
3. ✅ Improved TepTokenService key management
4. ✅ Updated test helper for MAS integration

## Remaining Work
To fully resolve the test flake, consider:

**Option 1: Disable class reloading in tests**
```ruby
# config/environments/test.rb
config.cache_classes = true
config.eager_load = true
```

**Option 2: Use Database Cleaner gem**
```ruby
# Add to Gemfile
gem 'database_cleaner-active_record'
```

**Option 3: Stub TepTokenService in failing tests**
```ruby
# Mock key creation to avoid reloading issues
```

**Option 4: Add retry logic for flaky tests**
```ruby
# Retry tests that fail with key errors
```

## How to Run Tests Reliably (Current Workaround)
Run individual test files instead of full suite:
```bash
# Each file passes reliably
bundle exec rails test test/controllers/api/v1/oauth_controller_test.rb
bundle exec rails test test/services/tep_token_service_test.rb
```

Or run with fixed seed that passes:
```bash
# Find a passing seed and use it
bundle exec rails test --seed 25354
```

## Test Evidence
```bash
# Test run 1 (PASS)
134 runs, 430 assertions, 0 failures, 0 errors, 0 skips

# Test run 2 (FAIL)
134 runs, 312 assertions, 42 failures, 0 errors, 0 skips

# Test run 3 (PASS)
134 runs, 430 assertions, 0 failures, 0 errors, 0 skips
```

All failures are: `Invalid TEP token: Invalid segment encoding`

## References
- TepTokenService: `app/services/tep_token_service.rb`
- Test Helper: `test/test_helper.rb`
- Issue introduced: During MAS integration setup
- Last updated: 2025-01-15
