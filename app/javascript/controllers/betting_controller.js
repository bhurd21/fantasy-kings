import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "betDescription", "stakeInput", "selectedBet", "budgetInfo", 
                     "weeklyBudget", "budgetUsed", "budgetRemaining", "stakeError", "confirmButton", "currentWeek"]
  
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
    
    // Store the selected bet
    this.selectedBetTarget.value = betId
    
    // Update modal content
    this.betDescriptionTarget.textContent = betDescription
    
    // Clear previous stake input
    this.stakeInputTarget.value = ""
    this.stakeErrorTarget.classList.add("hidden")
    
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
    } else {
      this.stakeErrorTarget.classList.add("hidden")
      this.confirmButtonTarget.disabled = false
    }
  }
  
  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.selectedBetTarget.value = ""
    this.stakeInputTarget.value = ""
    this.stakeErrorTarget.classList.add("hidden")
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
    const seasonStart = new Date(year, 8, 1) // September 1
    const daysSinceStart = Math.floor((currentDate - seasonStart) / (1000 * 60 * 60 * 24))
    const week = Math.floor(daysSinceStart / 7) + 1
    return Math.max(1, Math.min(week, 24))
  }
}
