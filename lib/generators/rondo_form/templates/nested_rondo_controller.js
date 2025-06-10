import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "fieldContain"]
  static values = { "fieldClass" : String }

  addField(e) {
    e.preventDefault();

    const newField = this.buildNewAssociation(e);
    this.fieldContainTarget.insertAdjacentHTML("beforeend", newField);
  }

  removeField(e) {
    e.preventDefault();
    const wrapperField = this.hasFieldClassValue ? e.target.closest("." + this.fieldClassValue) : e.target.parentNode;

    if(e.target.matches('.dynamic')) {
      wrapperField.remove();
    } else {
      wrapperField.querySelector("input[name*='_destroy']").value = 1;
      wrapperField.style.display = "none";
    }
  }

  buildNewAssociation(event) {
    let element = event.target;
    while (element) {
      if (element.hasAttribute('data-association') || element.hasAttribute('data-associations'))
        break
      element = element.parentElement;
    }
    const assoc = element.dataset.association;
    const assocs = element.dataset.associations;
    
    // Find the template - check if there's a specific template ID in the link
    let template = this.templateTarget;
    const templateId = element.dataset.templateId;
    if (templateId) {
      template = document.getElementById(templateId);
    }
    
    const content  = template.innerHTML;

    let regexpBraced = new RegExp('\\[new_' + assoc + '\\](.*?\\s)', 'g');
    let newId  = new Date().getTime();
    let newContent = content.replace(regexpBraced, '[' + newId + ']$1');

    if (newContent == content) {
      // assoc can be singular or plural
      regexpBraced = new RegExp('\\[new_' + assocs + '\\](.*?\\s)', 'g');
      newContent = content.replace(regexpBraced, '[' + newId + ']$1');
    }
    
    // Handle discriminator fields if present
    const discriminatorField = template.dataset.discriminatorField;
    const discriminatorValue = template.dataset.discriminatorValue;
    
    if (discriminatorField && discriminatorValue) {
      // Create a temporary container to manipulate the HTML
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = newContent;
      
      // Find and set the discriminator field value
      const discriminatorInput = tempDiv.querySelector(`input[name*='[${discriminatorField}]']`);
      if (discriminatorInput) {
        discriminatorInput.value = discriminatorValue;
      }
      
      newContent = tempDiv.innerHTML;
    }
    
    return newContent;
  }
}
