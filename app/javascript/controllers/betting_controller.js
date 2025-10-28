import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "betDescription", "stakeInput", "selectedBet", "budgetInfo", 
                     "weeklyBudget", "budgetUsed", "budgetRemaining", "stakeError", "confirmButton", "currentWeek",
                     "selectedOdds", "potentialWinnings", "winningsAmount", "totalPayout"]
  
  connect() {
    console.log("Betting controller connected")
    this.currentWeek = this.calculateCurrentWeek()
    console.log(`Calculated current week: ${this.currentWeek}`)
    this.minBet = 1
    this.maxBet = 9
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
      console.log(`Fetching budget for week: ${this.currentWeek}`)
      const response = await fetch(`/weekly_budget/${this.currentWeek}`)
      const data = await response.json()
      
      console.log('Budget data received:', data)
      
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
}
