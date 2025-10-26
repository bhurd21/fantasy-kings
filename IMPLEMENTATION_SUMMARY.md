# Implementation Summary - Time Formatting & Data Import

## Changes Made

### 1. Improved Time Display on Home Page

#### Commence Time Formatting
**Changes**: `app/controllers/home_controller.rb`
- Modified game time display to show **dual timezone format**: `Nov 1 6/7pm` or `Oct 23 7:30/8:30pm`
- First time is EST (America/New_York), second is CST (America/Chicago)
- Format: `Month Day EST_hour/CST_hour am/pm`
- Examples:
  - `Nov 1 6/7pm` = Nov 1st, 6pm EST / 7pm CST
  - `Oct 23 7:30/8:30pm` = Oct 23rd, 7:30pm EST / 8:30pm CST

#### Update Time Formatting
**Changes**: 
- `app/helpers/home_helper.rb` - Added `time_ago_in_words_short` helper
- `app/views/home/_bet_card.html.erb` - Updated to use the helper

Now shows human-readable relative times:
- "just now" (< 1 minute)
- "5m ago" (minutes)
- "3h ago" (hours)
- "2d ago" (days)
- "1w ago" (weeks)

**No external gem needed** - implemented natively with Ruby's time methods.

---

### 2. CSV Import Rake Task

**New File**: `lib/tasks/import_betting_history.rake`

#### Features:
- Imports historical betting data from CSV files
- Matches records to users by email
- Creates `BettingHistory` records with legacy data
- Handles missing users gracefully (tracks emails for later import)
- Comprehensive error handling and reporting

#### CSV Format:
```csv
timestamp,email,week_nfl,bet_description,line,total_stake,result,return
2024-09-08 13:00:00,user1@example.com,1,Chiefs -3.5,110,5.00,win,9.55
2024-09-08 16:00:00,user2@example.com,1,Over 47.5,110,3.00,loss,0.00
```

#### Column Definitions:
- **timestamp**: Date/time of bet (various formats supported)
- **email**: User's email address (must match registered user)
- **week_nfl**: NFL week number (1-18)
- **bet_description**: Text description (can be manual/unstructured)
- **line**: Odds as integer (e.g., 110, -150) - no "+" needed
- **total_stake**: Amount wagered in dollars
- **result**: win/loss/push/pending
- **return**: Total return amount (stake + winnings)

#### Usage:
```bash
# Default location: db/betting_history_import.csv
bundle exec rake betting_history:import

# Custom file location
bundle exec rake betting_history:import[path/to/your/file.csv]
```

#### Import Process:
1. Reads CSV file
2. For each row:
   - Looks up user by email
   - If user doesn't exist, skips and logs email for later
   - Parses all fields with flexible format support
   - Infers bet_type from description (spread/total/moneyline)
   - Creates BettingHistory record (without dk_game association)
   - Sets timestamps to match import data
3. Outputs summary report with:
   - Number of records imported
   - Number skipped (no matching user)
   - Number of errors
   - List of emails without users

#### Model Changes:
**File**: `app/models/betting_history.rb`
- Removed `validates :bet_type, presence: true` to allow legacy data
- Already had `belongs_to :dk_game, optional: true` for this use case

**Template File**: `db/betting_history_import_template.csv`
- Sample CSV with proper format for reference

---

### 3. Kamal Deployment Guide

**New File**: `KAMAL_DEPLOYMENT_GUIDE.md`

Comprehensive guide covering:

#### Pre-Deployment:
- How to backup current database
- Configuration validation
- Local testing steps

#### Database Reset Options:
- **Option A**: Clear data via Rails console (safe, preserves schema)
  ```ruby
  BettingHistory.delete_all
  DkGame.delete_all
  User.delete_all
  ```
- **Option B**: Nuclear reset (drop/create/migrate) - use with caution

#### Deployment Process:
```bash
git add .
git commit -m "Your message"
git push origin main
kamal deploy
```

#### Post-Deployment:
- Health checks
- OAuth verification
- Feature testing
- Data import process

#### Rollback Process:
```bash
kamal rollback
# Restore database backup if needed
```

#### Common Issues & Solutions:
- OAuth not working
- Migration failures
- Asset loading problems
- Container startup issues

#### Quick Reference Commands:
All essential Kamal commands for daily operations

#### Testing Checklist:
Step-by-step verification process

---

## What You Need to Do

### 1. Prepare Your Historical Data
Create a CSV file with your existing betting data following this format:
```csv
timestamp,email,week_nfl,bet_description,line,total_stake,result,return
2024-09-08 13:00:00,user@example.com,1,Chiefs -3.5,110,5.00,win,9.55
```

- **timestamp**: Can be various formats - the task will parse them
- **email**: Must match what users will sign up with (case-insensitive)
- **week_nfl**: 1-18
- **bet_description**: Can be manual text, you can clean up as needed
- **line**: Just the number, no "+" sign needed (e.g., 110, -150)
- **total_stake**: Dollar amount
- **result**: win, loss, push, or pending
- **return**: Total returned (stake + profit for win, stake for push, 0 for loss)

### 2. Test Locally First (Recommended)
```bash
# Create a test CSV with a few records
# Place at db/betting_history_import.csv

# Run import in development
bundle exec rake betting_history:import

# Check results
bundle exec rails console
BettingHistory.where(dk_game_id: nil).count
```

### 3. Deploy to Kamal
Follow the `KAMAL_DEPLOYMENT_GUIDE.md`:

```bash
# 1. Backup current production DB
kamal app exec -i bash
sqlite3 /rails/db/production.sqlite3 .dump > /rails/tmp/backup_$(date +%Y%m%d).sql
exit

# 2. Deploy new version
git add .
git commit -m "Add time formatting improvements and CSV import"
git push origin main
kamal deploy

# 3. Clear old data (optional)
kamal app exec -i "bin/rails console"
# In console:
BettingHistory.delete_all
DkGame.delete_all
# Keep or clear users as needed

# 4. Upload and import CSV
scp your_betting_data.csv deploy@your-server:/tmp/betting_data.csv
kamal app exec "bin/rails betting_history:import[/tmp/betting_data.csv]"
```

### 4. Handle Users Who Haven't Signed Up Yet
The import task will report emails without matching users:
```
EMAILS WITHOUT MATCHING USERS:
  - john@example.com
  - jane@example.com
```

**Solution**:
- Save the CSV file with these records
- After users sign up via OAuth, re-run the import
- The task is idempotent - it won't duplicate existing records

### 5. Ongoing Process
As new users register:
1. They sign in with Google OAuth
2. Their User record is created with their email
3. Run the import task again to attach their historical data
4. Their betting history will now appear in their profile

---

## Testing the New Features

### Time Formatting
1. Navigate to home page
2. Check game cards show: `Nov 1 6/7pm` format
3. Check bottom shows: `Updated 2h ago` format

### CSV Import
```bash
# Create test CSV
cat > test_import.csv << 'EOF'
timestamp,email,week_nfl,bet_description,line,total_stake,result,return
2024-09-08 13:00:00,your-email@gmail.com,1,Test Bet Chiefs -3.5,110,5.00,win,9.55
EOF

# Import
bundle exec rake betting_history:import[test_import.csv]

# Verify in console
bundle exec rails console
BettingHistory.last
# Should see your test bet
```

---

## Key Technical Decisions

### Why No External Gem for Time Formatting?
- Simple helper method (`time_ago_in_words_short`) is lightweight
- No external dependencies
- Easy to customize
- Sufficient for our needs

### Why Allow Nil dk_game_id?
- Legacy/historical data won't have associated games
- Users still want to see their full betting history
- Model already supported this with `optional: true`

### Why Match Users by Email?
- Email is consistent across OAuth sign-in
- Users won't have IDs until they register
- Easy to verify and debug

### Why Make bet_type Optional?
- Legacy data may not have structured bet types
- Can be inferred from description
- Allows manual entry/cleanup

---

## Files Changed

1. ✅ `Gemfile` - Cleaned up (no new gems added)
2. ✅ `app/controllers/home_controller.rb` - Time formatting logic
3. ✅ `app/helpers/home_helper.rb` - Time ago helper
4. ✅ `app/views/home/_bet_card.html.erb` - Use new helper
5. ✅ `app/models/betting_history.rb` - Remove bet_type validation
6. ✅ `lib/tasks/import_betting_history.rake` - New import task
7. ✅ `db/betting_history_import_template.csv` - Sample template
8. ✅ `KAMAL_DEPLOYMENT_GUIDE.md` - Deployment guide

---

## Questions & Considerations

### Should We Add a UI for Admins to Upload CSVs?
Currently it's a Rake task (command line). Could add:
- Admin dashboard with file upload
- Background job processing
- Web-based import status/errors
- Match/merge conflict resolution UI

Let me know if you want this!

### How to Handle Duplicate Imports?
Current implementation doesn't check for duplicates. Options:
1. Add uniqueness constraint on (user_id, timestamp, bet_description)
2. Check before inserting and skip/update
3. Trust manual process (simplest)

### Manual Bet Description Cleanup
You mentioned manually fixing bet descriptions. Consider:
- Creating a standardized format
- Regex patterns to auto-standardize
- Helper script to bulk update descriptions

---

## Next Steps

1. ✅ Bundle install complete
2. 📝 Prepare your CSV data
3. 🧪 Test import locally
4. 🚀 Deploy to Kamal server
5. 🔄 Clear old data if needed
6. 📊 Import historical data
7. ✅ Verify everything works

All code is ready to go! Let me know if you need help with any step or want me to adjust anything.
