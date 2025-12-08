import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "betDescription", "stakeInput", "selectedBet", "budgetInfo",
                     "weeklyBudget", "budgetUsed", "budgetRemaining", "stakeError", "confirmButton", "currentWeek",
                     "selectedOdds", "potentialWinnings", "winningsAmount", "totalPayout",
                     "searchInput", "clearButton", "ncaafButton", "nflButton", "ncaabButton"]

  connect() {
    this.currentWeek = this.calculateCurrentWeek()
    this.minBet = 1
    this.maxBet = 9
    this.activeLeagueFilter = null
    // NCAAB starts in hidden state - games are filtered out by default
    this.ncaabState = 'hidden' // 'hidden', 'active', or 'inactive'
    this.applyFilters()
  }
  
  async selectBet(event) {
    const button = event.currentTarget
    const betId = button.dataset.betId
    const betDescription = button.dataset.betDescription
    const betOdds = button.dataset.betOdds
    
    // Store the selected bet and odds
    this.selectedBetTarget.value = betId
    this.selectedOddsTarget.value = betOdds
    
    // Update modal content
    this.betDescriptionTarget.textContent = betDescription
    
    // Clear previous stake input and hide winnings
    this.stakeInputTarget.value = ""
    this.stakeErrorTarget.classList.add("hidden")
    this.potentialWinningsTarget.classList.add("hidden")
    
    // Fetch and display budget info
    await this.loadBudgetInfo()
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    
    // Focus on stake input
    this.stakeInputTarget.focus()
  }
  
  async loadBudgetInfo() {
    try {
      const response = await fetch(`/weekly_budget/${this.currentWeek}`)
      const data = await response.json()

      this.currentWeekTarget.textContent = data.week
      this.weeklyBudgetTarget.textContent = `$${data.budget.toFixed(2)}`
      this.budgetUsedTarget.textContent = `$${data.used.toFixed(2)}`
      this.budgetRemainingTarget.textContent = `$${data.remaining.toFixed(2)}`

      this.budgetRemaining = data.remaining
      this.minBet = data.min_bet
      this.maxBet = data.max_bet
    } catch (error) {
      console.error("Error loading budget info:", error)
    }
  }
  
  validateStake() {
    const stake = parseFloat(this.stakeInputTarget.value)
    let errorMessage = ""
    
    if (isNaN(stake) || stake <= 0) {
      this.confirmButtonTarget.disabled = true
      this.potentialWinningsTarget.classList.add("hidden")
      return
    }
    
    if (stake < this.minBet) {
      errorMessage = `Minimum bet is $${this.minBet}`
    } else if (stake > this.maxBet) {
      errorMessage = `Maximum bet is $${this.maxBet}`
    } else if (stake > this.budgetRemaining) {
      errorMessage = `Insufficient budget. You have $${this.budgetRemaining.toFixed(2)} remaining`
    }
    
    if (errorMessage) {
      this.stakeErrorTarget.textContent = errorMessage
      this.stakeErrorTarget.classList.remove("hidden")
      this.confirmButtonTarget.disabled = true
      this.potentialWinningsTarget.classList.add("hidden")
    } else {
      this.stakeErrorTarget.classList.add("hidden")
      this.confirmButtonTarget.disabled = false
      this.calculatePotentialWinnings(stake)
    }
  }
  
  calculatePotentialWinnings(stake) {
    const odds = this.selectedOddsTarget.value
    if (!odds || odds === "—") {
      this.potentialWinningsTarget.classList.add("hidden")
      return
    }
    
    // Parse American odds (e.g., "+150", "-110")
    const numericOdds = parseInt(odds.replace('+', ''))
    let potentialWinnings = 0
    
    if (numericOdds > 0) {
      // Positive odds: profit = (stake * odds) / 100
      potentialWinnings = (stake * numericOdds) / 100
    } else {
      // Negative odds: profit = stake / (Math.abs(odds) / 100)
      potentialWinnings = stake / (Math.abs(numericOdds) / 100)
    }
    
    const totalPayout = stake + potentialWinnings
    
    this.winningsAmountTarget.textContent = `$${potentialWinnings.toFixed(2)}`
    this.totalPayoutTarget.textContent = `$${totalPayout.toFixed(2)}`
    this.potentialWinningsTarget.classList.remove("hidden")
  }
  
  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.selectedBetTarget.value = ""
    this.selectedOddsTarget.value = ""
    this.stakeInputTarget.value = ""
    this.stakeErrorTarget.classList.add("hidden")
    this.potentialWinningsTarget.classList.add("hidden")
    this.confirmButtonTarget.disabled = false
  }
  
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }
  
  handleKeydown(event) {
    if (event.key === "Enter" && this.stakeInputTarget.value && !this.confirmButtonTarget.disabled) {
      event.preventDefault()
      this.element.querySelector("form").requestSubmit()
    }
  }
  
  calculateCurrentWeek() {
    const currentDate = new Date()
    const year = currentDate.getFullYear()

    // Weeks will change on Tuesday at 3 AM EST
    const seasonStart = new Date(year, 8, 2, 3, 0, 0) // September 2, 3:00 AM

    const hoursSinceStart = Math.floor((currentDate - seasonStart) / (1000 * 60 * 60))
    const daysSinceStart = Math.floor(hoursSinceStart / 24)
    const week = Math.floor(daysSinceStart / 7) + 1
    return Math.max(1, Math.min(week, 24))
  }

  clearSearch() {
    this.searchInputTarget.value = ''
    this.clearButtonTarget.classList.add('hidden')
    this.applyFilters()
  }

  toggleLeagueFilter(event) {
    const button = event.currentTarget
    const league = button.dataset.league

    if (this.activeLeagueFilter === league) {
      // Toggle off if same button clicked
      this.activeLeagueFilter = null
      button.classList.remove('active')
    } else {
      // Remove active from all filter buttons (except ncaab which has special handling)
      this.element.querySelectorAll('.league-filter-button:not([data-league="ncaab"])').forEach(btn => {
        btn.classList.remove('active')
      })
      
      // Reset ncaab to hidden state when selecting another filter
      if (this.hasNcaabButtonTarget) {
        this.ncaabState = 'hidden'
        this.ncaabButtonTarget.classList.remove('active')
        this.ncaabButtonTarget.classList.add('hidden-filter')
      }

      this.activeLeagueFilter = league
      button.classList.add('active')
    }

    this.applyFilters()
  }

  // NCAAB has 3 states: hidden (default) -> active (only ncaab) -> inactive (all shown)
  toggleNcaabFilter() {
    // Clear other league filters first
    this.activeLeagueFilter = null
    this.element.querySelectorAll('.league-filter-button:not([data-league="ncaab"])').forEach(btn => {
      btn.classList.remove('active')
    })

    // Cycle through states: hidden -> active -> inactive -> hidden
    if (this.ncaabState === 'hidden') {
      this.ncaabState = 'active'
      this.ncaabButtonTarget.classList.remove('hidden-filter')
      this.ncaabButtonTarget.classList.add('active')
    } else if (this.ncaabState === 'active') {
      this.ncaabState = 'inactive'
      this.ncaabButtonTarget.classList.remove('active')
      this.ncaabButtonTarget.classList.remove('hidden-filter')
    } else {
      this.ncaabState = 'hidden'
      this.ncaabButtonTarget.classList.remove('active')
      this.ncaabButtonTarget.classList.add('hidden-filter')
    }

    this.applyFilters()
  }

  filterCards(event) {
    const searchTerm = event.target.value.toLowerCase().trim()

    if (searchTerm) {
      this.clearButtonTarget.classList.remove('hidden')
    } else {
      this.clearButtonTarget.classList.add('hidden')
    }

    this.applyFilters()
  }

  applyFilters() {
    const searchTerm = this.searchInputTarget.value.toLowerCase().trim()
    const betCards = document.querySelectorAll('.bet-card')

    betCards.forEach(card => {
      const awayTeam = card.dataset.awayTeam?.toLowerCase() || ''
      const homeTeam = card.dataset.homeTeam?.toLowerCase() || ''
      const league = card.dataset.league

      const matchesSearch = searchTerm === '' || awayTeam.includes(searchTerm) || homeTeam.includes(searchTerm)
      
      // Handle league filtering with special NCAAB logic
      let matchesLeague = true
      if (this.activeLeagueFilter !== null) {
        // Standard filter active (nfl or ncaaf)
        matchesLeague = league === this.activeLeagueFilter
      } else if (this.ncaabState === 'hidden') {
        // NCAAB is hidden by default - filter out ncaab games
        matchesLeague = league !== 'ncaab'
      } else if (this.ncaabState === 'active') {
        // Only show ncaab games
        matchesLeague = league === 'ncaab'
      }
      // ncaabState === 'inactive' means show all (matchesLeague stays true)

      if (matchesSearch && matchesLeague) {
        card.style.display = ''
      } else {
        card.style.display = 'none'
      }
    })
  }
}
