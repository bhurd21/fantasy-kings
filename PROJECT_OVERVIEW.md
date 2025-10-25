# Fantasy Kings - Project Overview

## Application Architecture

This is a Ruby on Rails 8 application for sports betting tracking, specifically focused on NFL games. The app allows users to sign in via OAuth (Google), view available bets from DraftKings, place bets, and track their betting history and performance.

## Technology Stack

- **Framework**: Ruby on Rails 8
- **Database**: SQLite (development)
- **Authentication**: OAuth 2.0 (Google)
- **Frontend**: ERB templates with embedded styles, importmap for JavaScript
- **Deployment**: Docker/Kamal ready

---

## Page Rendering Flow

### 1. **Sign In Page** (`/sign_in`)

**Route**: `GET /sign_in`

**Controller**: `AuthController#sign_in`
- Located in: `app/controllers/auth_controller.rb`
- Skips authentication requirement
- Simply renders the sign-in view

**View**: `app/views/auth/sign_in.html.erb`
- Displays a centered "Sign in with Google" button
- Links to OAuth flow via `/oauth/google`
- Contains embedded CSS for basic styling

**Authentication Flow**:
1. User clicks "Sign in with Google"
2. Routes to `OauthController#show` with provider="google"
3. Redirects to Google OAuth authorization
4. Google redirects back to `/auth/google_oauth2/callback`
5. `OauthController#callback` processes the OAuth response
6. Creates/finds user and sets session
7. Redirects to root path

---

### 2. **Home Page / Betting Dashboard** (`/`)

**Route**: `GET /` (root)

**Controller**: `HomeController#index`
- Located in: `app/controllers/home_controller.rb`
- Requires authentication via `before_action :require_user`
- Redirects to sign-in if user not authenticated

**Data Flow**:
1. Filters `DkGame` records to only show upcoming games (commence_time > current time)
2. Orders games by commence_time ascending (earliest first)
3. Converts UTC times to local timezone for display
4. Transforms game data into betting options hash array containing:
   - Game details (teams, commence time in local timezone)
   - Spread bets (home/away with odds)
   - Total bets (over/under with odds)
   - Moneyline bets (winner odds)
5. Formats odds and spreads using helper methods
6. Assigns to `@bets` instance variable

**View**: `app/views/home/index.html.erb`
- Clean, modular structure using partials (~54 lines, down from 393)
- Displays user greeting with current_user.name
- Uses Stimulus controller (`betting_controller.js`) for interactivity
- Renders bet cards using `_bet_card.html.erb` partial
- Modal dialog for bet confirmation with stake input
- Partials used:
  - `_bet_card.html.erb`: Individual game card with betting grid
  - `_bet_option.html.erb`: Individual betting button
  - `_betting_styles.html.erb`: All CSS styles
- Clicking a bet opens a modal to enter stake amount
- Modal features:
  - Displays selected bet description
  - Numeric input for stake amount
  - Cancel and Confirm buttons
  - Submit on Enter key
  - Close on backdrop click

**JavaScript**: `app/javascript/controllers/betting_controller.js`
- Stimulus controller for bet selection and modal management
- Handles bet button clicks
- Opens/closes modal with animations
- Manages stake input and form submission
- Keyboard navigation support

**Layout**: `app/views/layouts/application.html.erb`
- Wraps all pages
- Includes meta tags, PWA support, favicon
- Loads CSS and JavaScript via importmap
- Conditionally renders bottom navigation if user is logged in

---

### 3. **Bet Submission** (`POST /bets`)

**Route**: `POST /bets`

**Controller**: `HomeController#create_bet`
- Receives `selected_bet` parameter (format: "game_id_bet_type")
- Receives `stake` parameter (user-entered amount)
- Validates that bet selection exists
- Validates that stake amount is greater than 0
- Parses game ID and bet type
- Looks up `DkGame` record
- Determines line value based on bet type
- Creates `BettingHistory` record with:
  - Associated user and game
  - Bet type and line value
  - User-specified stake amount
  - Result status of "pending"
- Sets flash message (notice or alert) including stake amount
- Redirects back to root path

---

### 4. **Week View** (`/week/:week`)

**Route**: `GET /week/:week`

**Controller**: `HomeController#week`
- Requires authentication
- Extracts week number from URL params
- Queries `BettingHistory` with:
  - Eager loads associated user and dk_game
  - Filters by NFL week number
  - Orders by creation date (descending)

**View**: `app/views/home/week.html.erb`
- Displays header with week number
- Lists all bets placed for that week
- Shows for each bet:
  - User name
  - Bet description (formatted)
  - Line value
  - Stake amount
  - Result status (with color coding)
- Empty state if no bets
- Embedded CSS with dark theme

---

### 5. **Profile Page** (`/profile`)

**Route**: `GET /profile`

**Controller**: `HomeController#profile`
- Requires authentication
- Calculates user statistics:
  - `@total_wagered`: sum of all stakes
  - `@total_profit_loss`: calculated from bet results
  - `@win_percentage`: wins / total decided bets
- Fetches user's betting history with eager loading

**View**: `app/views/home/profile.html.erb`
- Header with user name and logout button
- Three stat cards showing:
  - Total wagered
  - Profit/Loss (colored based on positive/negative)
  - Win rate percentage
- Betting history section listing:
  - Date and week
  - Bet description
  - Line value
  - Stake
  - Profit/Loss with color coding
  - Result badge
- Empty state if no history
- Embedded CSS with dark theme

---

### 6. **Settings Page** (`/settings`)

**Route**: `GET /settings`

**Controller**: `HomeController#settings`
- Requires authentication
- Currently a placeholder (no data processing)

**View**: `app/views/home/settings.html.erb`
- Simple settings display
- Shows account email
- Shows user name
- Logout button
- Embedded CSS with dark theme

---

### 7. **Betting History Index** (`/betting_histories`)

**Route**: Not explicitly defined in routes.rb but controller exists

**Controller**: `BettingHistoriesController#index`
- Located in: `app/controllers/betting_histories_controller.rb`
- Requires authentication
- Fetches user's betting histories with pagination
- Calculates summary statistics
- Supports filtering by:
  - Week number
  - Result status (pending/win/loss/push)
- Uses Kaminari or similar for pagination (20 per page)

**View**: `app/views/betting_histories/index.html.erb`
- Desktop-focused view (uses Tailwind CSS classes)
- Summary stats in three-column grid
- Filter form with week and result dropdowns
- Full data table showing:
  - Date, Week, Bet details
  - Line, Stake, Result
  - P&L and ROI
- Pagination controls
- Link to place new bets

---

### 8. **OAuth Callback** (`/auth/:provider/callback`)

**Route**: `GET /auth/:provider/callback`

**Controller**: `OauthController#callback`
- Exchanges OAuth code for access token
- Fetches user info from provider (Google)
- Finds or creates User record with:
  - Provider name
  - UID from OAuth
  - Email and name
- Sets session[:user_id] and session[:user_info]
- Redirects to root path with success message
- Handles OAuth errors with redirect to sign-in

---

### 9. **Logout** (`/logout`)

**Route**: `GET /logout`

**Controller**: `OauthController#logout`
- Clears session[:user_id]
- Clears session[:user_info]
- Redirects to sign-in page

---

## Data Models

### **User** (`app/models/user.rb`)
- Has many `betting_histories`
- Stores OAuth data: provider, uid, email, name
- Methods for calculating:
  - `total_wagered`
  - `total_profit_loss`
  - `win_percentage`

### **DkGame** (`app/models/dk_game.rb`)
- Represents a sports game with betting lines
- Enum for sport type (nfl, ncaaf)
- Has many `betting_histories`
- Stores:
  - Teams (home/away)
  - Commence time
  - Spread data (points and odds)
  - Total data (points, over/under odds)
  - Moneyline odds
  - Bookmaker update timestamp
- Auto-generates unique_id from teams and date

### **BettingHistory** (`app/models/betting_history.rb`)
- Belongs to User and DkGame
- Enum for result: pending, win, loss, push
- Stores:
  - Bet type (spread, moneyline, total)
  - Line value (odds)
  - Stake amount
  - Return amount
  - NFL week number
  - Bet description
- Methods for:
  - `profit_loss`: calculated return minus stake
  - `roi_percentage`: profit/loss ratio
  - `formatted_line`: display formatting
  - `formatted_description`: human-readable bet
- Auto-calculates NFL week on creation

---

## Application Flow

### **Authentication Flow**:
1. All pages except sign-in require authentication (`ApplicationController#require_authentication`)
2. Unauthenticated users redirected to `/sign_in`
3. OAuth via Google creates/authenticates users
4. Session stores user_id for subsequent requests
5. `current_user` helper method available throughout app

### **Navigation**:
- Bottom navigation bar rendered conditionally when user logged in
- Appears on: home, week views, profile, settings
- Defined in: `app/views/layouts/_bottom_nav.html.erb`

### **Data Import**:
- Rake task exists: `lib/tasks/import_dk_games.rake`
- Likely imports game and betting line data from external API
- Populates DkGame records

---

## Key Features

1. **OAuth Authentication**: Secure Google sign-in
2. **Live Betting Lines**: Display current DraftKings odds for upcoming games only
3. **Timezone Handling**: Automatic conversion from UTC to local timezone
4. **Bet Placement**: Modal-based bet confirmation with stake input
5. **Betting Tracking**: Historical record of all placed bets with stake amounts
6. **Statistics Dashboard**: Win rate, P&L, total wagered
7. **Week-by-Week View**: See community/user bets per NFL week
8. **Mobile-First Design**: Dark theme, touch-friendly UI with modal interactions
9. **Profile Management**: View personal betting history and stats
10. **Stimulus JS**: Modern, reliable JavaScript interactions using Stimulus controllers

---

## Helper Methods

### **HomeController Helpers**:
- `format_spread(point)`: Formats spread with +/- sign
- `format_odds(odds)`: Formats betting odds with +/- sign
- `get_line_value(game, bet_type)`: Retrieves odds for bet type

### **ApplicationController Helpers**:
- `current_user`: Returns logged-in user or nil
- `require_authentication`: Before action to enforce login

### **BettingHistoryHelper** (referenced but not shown):
- `format_line(bet_type, line_value)`: Formats betting line
- `format_bet_description(betting_history)`: Creates human-readable bet string
- `format_currency(amount)`: Formats dollar amounts
- `profit_loss_class(amount)`: CSS class for positive/negative
- `result_badge_class(result)`: CSS class for result status

---

## File Structure Summary

```
app/
├── controllers/
│   ├── application_controller.rb      # Base controller with auth
│   ├── home_controller.rb              # Main betting interface
│   ├── auth_controller.rb              # Sign-in page
│   ├── oauth_controller.rb             # OAuth flow handling
│   └── betting_histories_controller.rb # Betting history management
│
├── models/
│   ├── user.rb                         # User with stats methods
│   ├── dk_game.rb                      # Game and betting lines
│   └── betting_history.rb              # Individual bet records
│
├── views/
│   ├── layouts/
│   │   ├── application.html.erb        # Main layout wrapper
│   │   └── _bottom_nav.html.erb        # Mobile navigation
│   ├── auth/
│   │   └── sign_in.html.erb            # OAuth sign-in
│   ├── home/
│   │   ├── index.html.erb              # Main betting dashboard (clean, ~54 lines)
│   │   ├── _bet_card.html.erb          # Partial: Individual game card
│   │   ├── _bet_option.html.erb        # Partial: Betting button
│   │   ├── _betting_styles.html.erb    # Partial: All CSS styles
│   │   ├── week.html.erb               # Week-specific bets
│   │   ├── profile.html.erb            # User stats and history
│   │   └── settings.html.erb           # Settings page
│   └── betting_histories/
│       └── index.html.erb              # Full history with filters
│
├── javascript/
│   └── controllers/
│       ├── application.js              # Stimulus application setup
│       ├── betting_controller.js       # Bet selection & modal logic
│       ├── hello_controller.js         # Example controller
│       └── index.js                    # Controller registration
│
└── helpers/
    ├── application_helper.rb
    ├── home_helper.rb
    └── betting_history_helper.rb
```

---

## Styling Approach

- **Modular CSS**: Styles separated into partials for reusability
- **No external CSS framework** on most pages (except betting_histories/index uses Tailwind)
- Consistent dark theme (#111 background, #1a1a1a cards, #212121 buttons)
- Mobile-first responsive design
- Modern modal overlays with backdrop blur effects
- Smooth transitions and hover states

---

## Recent Refactoring (October 2025)

### Betting Interface Improvements:
- **Reduced complexity**: Main index.html.erb reduced from 393 lines to ~54 lines
- **Stimulus JS**: Replaced unreliable vanilla JS with Stimulus controller pattern
- **Modal workflow**: Bet selection now opens modal for stake input instead of form submission
- **Partials**: Broke monolithic view into reusable components
- **Timezone handling**: Automatic UTC to local timezone conversion
- **Game filtering**: Only shows upcoming games (past games automatically hidden)
- **Improved sorting**: Games displayed in chronological order (earliest first)
- **Validation**: Added stake amount validation before bet creation

### Benefits:
- More maintainable codebase
- More reliable JavaScript behavior
- Better user experience with modal interactions
- Easier to test and extend
- Follows Rails conventions and best practices

---

## Future Enhancements (Implied)

- Admin panel for managing games and results
- Automated result calculation from APIs
- Real-time odds updates via WebSockets or ActionCable
- Push notifications for game starts
- Social features (following users, leaderboards)
- Edit/delete bet functionality
- More detailed analytics and charts
- Bet history filtering and search
- Multiple stake presets (quick bet amounts)
