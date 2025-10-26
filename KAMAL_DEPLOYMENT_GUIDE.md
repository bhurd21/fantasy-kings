# Kamal Deployment Testing Guide

## Overview
This guide covers how to test deploying these updates to your Kamal server, including clearing all database records while preserving the Google OAuth configuration.

## Pre-Deployment Steps

### 1. Backup Current Database
Before clearing data, create a backup:

```bash
# SSH into your server
kamal app exec -i bash

# Inside the container, backup the database
sqlite3 /rails/db/production.sqlite3 .dump > /rails/tmp/backup_$(date +%Y%m%d).sql

# Exit container
exit

# Download backup to local machine
kamal app exec "cat /rails/tmp/backup_$(date +%Y%m%d).sql" > backup_$(date +%Y%m%d).sql
```

### 2. Check Current Kamal Configuration
Review your `config/deploy.yml`:

```bash
cat config/deploy.yml
```

Make sure your server details, registry, and environment variables are correct.

### 3. Test Configuration Locally
```bash
# Validate deploy config
kamal config

# Check if server is accessible
kamal server exec "echo 'Connection successful'"
```

## Database Reset Options

### Option A: Clear Data via Rails Console (Preserves Schema)
This is the safest option - it keeps your database structure but removes data:

```bash
# Access Rails console on production
kamal app exec -i "bin/rails console"
```

Then in the console:
```ruby
# Clear betting histories first (foreign key dependencies)
BettingHistory.delete_all
puts "Cleared #{BettingHistory.count} betting histories"

# Clear DK games
DkGame.delete_all
puts "Cleared #{DkGame.count} DK games"

# Optionally keep some users for testing, or clear all non-admin users
# User.where.not(role: :admin).delete_all
# Or clear all users (they'll re-register via OAuth)
User.delete_all
puts "Cleared #{User.count} users"

# Verify
puts "Remaining records:"
puts "Users: #{User.count}"
puts "DK Games: #{DkGame.count}"
puts "Betting Histories: #{BettingHistory.count}"
```

### Option B: Reset Database Completely (Nuclear Option)
If you want to start completely fresh:

```bash
# Access container
kamal app exec -i bash

# Inside container
cd /rails
RAILS_ENV=production bin/rails db:drop db:create db:migrate db:seed

# Exit
exit
```

**Warning**: This will require you to reconfigure any OAuth secrets/credentials.

## Deployment Process

### 1. Commit Your Changes
```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Add improved time formatting, CSV import task, and betting updates"

# Push to repository
git push origin main
```

### 2. Deploy with Kamal
```bash
# Deploy the updated application
kamal deploy

# This will:
# - Build a new Docker image with your changes
# - Push it to your registry
# - Pull it on the server
# - Start the new container
# - Run any pending migrations
```

### 3. Monitor Deployment
```bash
# Watch the deployment logs
kamal app logs -f

# Check if the new version is running
kamal app version

# Check container status
kamal app details
```

### 4. Run Database Migrations
If you have new migrations:

```bash
# Run migrations on production
kamal app exec "bin/rails db:migrate"
```

### 5. Import Historical Betting Data
After deployment, upload and import your CSV:

```bash
# Upload CSV file to server
scp betting_history_data.csv deploy@your-server:/tmp/

# Run import task
kamal app exec "bin/rails betting_history:import[/tmp/betting_history_data.csv]"
```

## Post-Deployment Verification

### 1. Check Application Health
```bash
# Test health endpoint
curl https://your-domain.com/up

# Check if app is responding
curl -I https://your-domain.com
```

### 2. Test OAuth Flow
- Navigate to your sign-in page
- Attempt to sign in with Google
- Verify successful authentication and redirect

### 3. Verify New Features
- Check time formatting on home page (EST/CST dual timezone)
- Verify "Updated X hours ago" displays correctly
- Test bet placement still works
- Confirm budget tracking functions

### 4. Check Database Records
```bash
# Access Rails console
kamal app exec -i "bin/rails console"
```

```ruby
# Verify data
User.count
DkGame.count
BettingHistory.count

# Check a sample user
User.first&.email

# Check imported betting histories
BettingHistory.where(dk_game_id: nil).count
```

## Rollback Process

If something goes wrong:

```bash
# Rollback to previous version
kamal rollback

# This restores the previous container image
```

If you need to restore the database backup:

```bash
# Upload backup file
scp backup_20241025.sql deploy@your-server:/tmp/

# Restore
kamal app exec -i bash
cd /rails
sqlite3 db/production.sqlite3 < /tmp/backup_20241025.sql
exit
```

## Common Issues & Solutions

### Issue: OAuth Not Working After Deploy
**Solution**: Check environment variables
```bash
kamal env show
kamal secrets extract
```

Make sure `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are set.

### Issue: Migrations Fail
**Solution**: Run migrations manually
```bash
kamal app exec "bin/rails db:migrate:status"
kamal app exec "bin/rails db:migrate"
```

### Issue: Assets Not Loading
**Solution**: Precompile assets
```bash
kamal app exec "bin/rails assets:precompile"
```

### Issue: Container Won't Start
**Solution**: Check logs
```bash
kamal app logs --tail 100
kamal app details
```

## Quick Reference Commands

```bash
# Deploy
kamal deploy

# Check status
kamal app details

# View logs
kamal app logs -f

# Run console
kamal app exec -i "bin/rails console"

# Run bash
kamal app exec -i bash

# Restart app
kamal app restart

# Stop app
kamal app stop

# Start app
kamal app start

# SSH to server
kamal server exec -i bash

# Run rake task
kamal app exec "bin/rails task_name"
```

## Testing Checklist

- [ ] Backup current database
- [ ] Verify deploy.yml configuration
- [ ] Test local build: `docker build .`
- [ ] Commit and push changes
- [ ] Deploy: `kamal deploy`
- [ ] Monitor deployment logs
- [ ] Verify app is running
- [ ] Test OAuth sign-in
- [ ] Clear old database records (if needed)
- [ ] Import historical betting data
- [ ] Test new time formatting features
- [ ] Verify betting functionality works
- [ ] Check mobile responsiveness
- [ ] Test profile/stats pages
- [ ] Monitor for errors over next hour

## Notes

- **Google OAuth**: Your OAuth credentials should persist as environment variables in Kamal's `.env` file
- **Database**: SQLite file persists in a volume, so unless you explicitly delete it, data remains across deploys
- **Zero-downtime**: Kamal does rolling deploys by default, so your app stays up during deployment
- **First Deploy**: May take longer as it builds and pushes the initial image

## Environment Variables to Keep

Make sure these are in your `.env` or Kamal secrets:
```
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
RAILS_MASTER_KEY=your_master_key
SECRET_KEY_BASE=your_secret_key
```

## Next Steps After Testing

1. Monitor error logs for first few days
2. Import betting history CSV files as users register
3. Schedule regular backups
4. Set up monitoring/alerting (optional)
5. Consider database backup automation
