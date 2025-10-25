import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "betDescription", "stakeInput", "selectedBet"]
  
  connect() {
    console.log("Betting controller connected")
  }
  
  selectBet(event) {
    const button = event.currentTarget
    const betId = button.dataset.betId
    const betDescription = button.dataset.betDescription
    
    // Store the selected bet
    this.selectedBetTarget.value = betId
    
    // Update modal content
    this.betDescriptionTarget.textContent = betDescription
    
    // Clear previous stake input
    this.stakeInputTarget.value = ""
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    
    // Focus on stake input
    this.stakeInputTarget.focus()
  }
  
  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.selectedBetTarget.value = ""
    this.stakeInputTarget.value = ""
  }
  
  // Close modal when clicking outside
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }
  
  // Allow Enter key to submit
  handleKeydown(event) {
    if (event.key === "Enter" && this.stakeInputTarget.value) {
      event.preventDefault()
      this.element.querySelector("form").requestSubmit()
    }
  }
}
