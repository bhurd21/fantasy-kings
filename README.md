# Fantasy Kings - Development Setup

Rails 8 sports betting tracking application.

## Quick Start

### 1. Install Prerequisites
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install development tools
brew install rbenv ruby-build sqlite3
xcode-select --install

# Setup Ruby
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.2.0
rbenv global 3.2.0
```

### 2. Setup Project
```bash
git clone https://github.com/bhurd21/fantasy-kings.git
cd fantasy-kings
bundle install
bin/setup
```

The app will start at `http://localhost:3000`.

## Common Commands

```bash
bin/rails console           # Rails console
bin/rails db:migrate        # Run migrations  
bin/rails routes            # View routes
```

## Project Overview

**Models:** User, BettingHistory, DkGame  
**Database:** SQLite (development)  
**Auth:** OAuth 2.0 (Google/GitHub)  
**Frontend:** Turbo + Stimulus  

**User Roles:** Admin, Player, Viewer  
**Features:** Weekly betting budgets, leaderboards, DraftKings odds integration
