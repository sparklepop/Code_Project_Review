import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "scoreInput", "sectionTotal", "finalScore", "assessmentLevel" ]

  connect() {
    this.calculateTotals()
  }

  calculateTotals() {
    // Calculate section totals
    const qualityTotal = this.calculateSectionTotal("quality")
    const documentationTotal = this.calculateSectionTotal("documentation")
    const technicalTotal = this.calculateSectionTotal("technical")
    const problemSolvingTotal = this.calculateSectionTotal("problem_solving")
    const testingBonus = this.calculateSectionTotal("testing")

    // Calculate final score
    let finalScore = qualityTotal + documentationTotal + technicalTotal + problemSolvingTotal + testingBonus
    
    // Apply non-working solution deduction if checked
    if (this.element.querySelector("#code_review_non_working_solution").checked) {
      finalScore -= 30
    }

    this.updateAssessmentLevel(finalScore)
  }

  calculateSectionTotal(section) {
    return Array.from(this.element.querySelectorAll(`[data-section="${section}"]`))
      .reduce((sum, input) => sum + (parseInt(input.value) || 0), 0)
  }

  updateAssessmentLevel(score) {
    let level = "Does not meet requirements"
    if (score >= 95) level = "Outstanding - Strong Senior+ candidate"
    else if (score >= 85) level = "Excellent - Senior candidate"
    else if (score >= 75) level = "Good - Mid-level candidate"
    else if (score >= 65) level = "Fair - Junior candidate"

    this.assessmentLevelTarget.textContent = level
  }

  scoreChanged() {
    this.calculateTotals()
  }
} 