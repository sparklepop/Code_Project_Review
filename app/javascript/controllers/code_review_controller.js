import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submissionUrl", "form", "analyzeButton"]

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
    const defaultText = button.querySelector('.default-text')
    const analyzingText = button.querySelector('.analyzing-text')

    if (analyzing) {
      button.disabled = true
      defaultText.classList.add('d-none')
      analyzingText.classList.remove('d-none')
    } else {
      button.disabled = false
      defaultText.classList.remove('d-none')
      analyzingText.classList.add('d-none')
    }
  }

  fillForm(data) {
    // Fill quality scores
    Object.entries(data.quality_scores).forEach(([key, value]) => {
      this.setFieldValue('quality_scores', key, value)
    })

    // Fill documentation scores
    Object.entries(data.documentation_scores).forEach(([key, value]) => {
      this.setFieldValue('documentation_scores', key, value)
    })

    // Fill technical scores
    Object.entries(data.technical_scores).forEach(([key, value]) => {
      this.setFieldValue('technical_scores', key, value)
    })

    // Fill problem solving scores
    Object.entries(data.problem_solving_scores).forEach(([key, value]) => {
      this.setFieldValue('problem_solving_scores', key, value)
    })

    // Fill testing scores
    Object.entries(data.testing_scores).forEach(([key, value]) => {
      this.setFieldValue('testing_scores', key, value)
    })

    // Fill overall comments
    document.getElementById('code_review_overall_comments').value = data.overall_comments
  }

  setFieldValue(section, key, value) {
    const field = document.querySelector(`[name="code_review[${section}][${key}]"]`)
    if (field) field.value = value
  }
} 