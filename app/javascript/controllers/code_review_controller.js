import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "submissionUrl", 
    "form", 
    "analyzeButton", 
    "scoreInput",
    "analysisProgress"
  ]

  connect() {
    this.setupScoreInputs()
    // Hide progress indicator on initial load
    this.analysisProgressTarget.style.display = 'none'
  }

  setupScoreInputs() {
    this.scoreInputTargets.forEach(input => {
      input.addEventListener('change', this.updateScore.bind(this))
    })
  }

  async updateScore(event) {
    const input = event.target
    const scoreType = input.dataset.scoreType
    const scoreField = input.dataset.scoreField
    const value = input.value
    const reviewId = this.element.dataset.reviewId

    try {
      const response = await fetch(`/code_reviews/${reviewId}/update_score`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          score_type: scoreType,
          score_field: scoreField,
          value: value
        })
      })

      const result = await response.json()
      
      if (result.success) {
        // Update any total score displays if needed
        this.updateScoreDisplays(result)
      } else {
        console.error('Score update failed:', result.errors)
      }
    } catch (error) {
      console.error('Error updating score:', error)
    }
  }

  updateScoreDisplays(result) {
    // Update total score display if it exists
    const totalScoreElement = document.getElementById('total-score')
    if (totalScoreElement) {
      totalScoreElement.textContent = result.total_score
    }

    // Update section score if it exists
    const sectionScoreElement = document.getElementById('section-score')
    if (sectionScoreElement) {
      sectionScoreElement.textContent = result.section_score
    }
  }

  analyze() {
    const url = this.submissionUrlTarget.value
    if (!url) {
      this.showError("Please enter a submission URL")
      return
    }

    this.setAnalyzing(true)
    this.clearError()

    fetch('/code_reviews/analyze_submission', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        code_review: { submission_url: url }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.error) {
        this.showError(data.error);
        return;
      }
      this.fillForm(data);
    })
    .catch(error => {
      console.error('Error:', error);
      this.showError("Failed to analyze code. Please try again.");
    })
    .finally(() => {
      this.setAnalyzing(false)
    });
  }

  showError(message) {
    let errorDiv = document.getElementById('analyze-error')
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.id = 'analyze-error'
      errorDiv.className = 'alert alert-danger mt-2'
      this.analyzeButtonTarget.parentNode.appendChild(errorDiv)
    }
    errorDiv.textContent = message
  }

  clearError() {
    const errorDiv = document.getElementById('analyze-error')
    if (errorDiv) {
      errorDiv.remove()
    }
  }

  setAnalyzing(analyzing) {
    const button = this.analyzeButtonTarget
    const progress = this.analysisProgressTarget

    if (analyzing) {
      button.disabled = true
      progress.style.display = 'block'
    } else {
      button.disabled = false
      progress.style.display = 'none'
    }
  }

  debugFormFields() {
    const inputs = this.scoreInputTargets;
    console.log("All score input fields:", inputs.map(input => ({
      name: input.name,
      scoreType: input.dataset.scoreType,
      scoreField: input.dataset.scoreField,
      value: input.value
    })));
  }

  fillForm(data) {
    console.log("Filling form with data:", data);

    try {
      // Get all score input fields
      const scoreInputs = this.scoreInputTargets;
      console.log("Found score inputs:", scoreInputs.length);

      scoreInputs.forEach(input => {
        const scoreType = input.dataset.scoreType;
        const scoreField = input.dataset.scoreField;
        
        if (data[scoreType] && data[scoreType][scoreField] !== undefined) {
          console.log(`Setting ${scoreType}.${scoreField} to ${data[scoreType][scoreField]}`);
          input.value = data[scoreType][scoreField];
        }
      });

      // Handle comments separately
      const commentsField = document.getElementById('code_review_overall_comments');
      if (commentsField && data.overall_comments) {
        commentsField.value = data.overall_comments;
      }

      console.log("Form filling completed");
    } catch (error) {
      console.error("Error filling form:", error);
      this.showError("Error filling form with analysis results");
    }
  }
} 