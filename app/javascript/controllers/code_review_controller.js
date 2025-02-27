import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submissionUrl", "form", "analyzeButton", "scoreInput"]

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
    this.debugFormFields();
    console.log("Filling form with data:", data);

    try {
      // Remove previous indicators
      this.clearUpdateIndicators();

      // Get all score input fields
      const scoreInputs = this.scoreInputTargets;
      console.log("Found score inputs:", scoreInputs.length);

      scoreInputs.forEach(input => {
        const scoreType = input.dataset.scoreType;
        const scoreField = input.dataset.scoreField;
        
        if (data[scoreType] && data[scoreType][scoreField] !== undefined) {
          console.log(`Setting ${scoreType}.${scoreField} to ${data[scoreType][scoreField]}`);
          input.value = data[scoreType][scoreField];
          this.addUpdateIndicators(input);
        }
      });

      // Handle comments separately
      const commentsField = document.getElementById('code_review_overall_comments');
      if (commentsField && data.overall_comments) {
        commentsField.value = data.overall_comments;
        this.addUpdateIndicators(commentsField);
      }

      console.log("Form filling completed");
    } catch (error) {
      console.error("Error filling form:", error);
      this.showError("Error filling form with analysis results");
    }
  }

  clearUpdateIndicators() {
    document.querySelectorAll('.field-updated').forEach(el => {
      el.classList.remove('field-updated');
    });
    document.querySelectorAll('.field-updated-label').forEach(el => {
      el.classList.remove('field-updated-label');
    });
  }

  addUpdateIndicators(element) {
    element.classList.add('field-updated');
    const label = element.closest('.form-group').querySelector('label');
    if (label) {
      label.classList.add('field-updated-label');
    }
    
    // Remove highlight after animation
    setTimeout(() => {
      element.classList.remove('field-updated');
    }, 1000);
  }
} 