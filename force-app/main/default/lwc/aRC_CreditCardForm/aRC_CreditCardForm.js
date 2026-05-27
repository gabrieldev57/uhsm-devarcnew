import { LightningElement, api, track } from 'lwc';

/**
 * Credit Card Form - Handles ONLY card number and expiration
 * Account holder is managed by parent component (aRC_PaymentMethod)
 */
export default class ArcCreditCardForm extends LightningElement {
    @api readOnly = false;
    @api recordId = null;

    // Card payment data ONLY
    @track internalCardData = {
        cardNumber: '',
        expirationDate: ''
    };

    @track displayCardNumber = '';

    /**
     * @api Set card data (for pre-filling from existing data)
     */
    @api
    get cardData() {
        return this.internalCardData;
    }
    set cardData(value) {
        this.updateCardData(value);
    }

    @api updateCardData(data) {
        if (!data) return;
        
        // Handle new structure with cardData wrapper
        let cardInfo = data.cardData || data;
        
        // Create a copy to modify
        let newData = { ...this.internalCardData };

        // Set card number
        if (cardInfo && cardInfo.cardNumber !== undefined) {
            newData.cardNumber = cardInfo.cardNumber;
            this.displayCardNumber = this.formatCardNumberDisplay(cardInfo.cardNumber);
        }
        
        // Build expiration date from month/year
        if (cardInfo && cardInfo.expirationMonth && cardInfo.expirationYear) {
            const month = String(cardInfo.expirationMonth).padStart(2, '0');
            const year = String(cardInfo.expirationYear).slice(-2);
            newData.expirationDate = `${month}/${year}`;
        } else if (cardInfo && cardInfo.expirationDate !== undefined) {
            newData.expirationDate = cardInfo.expirationDate;
        }

        this.internalCardData = newData;
    }

    /**
     * Format card number for display (mask all but last 4 digits)
     */
    formatCardNumberDisplay(number) {
        if (!number) return '';
        // If masked, return as is
        if (number.includes('*')) return number;
        
        const cleaned = number.replace(/\D/g, '');
        const groups = cleaned.match(/.{1,4}/g) || [];
        return groups.join(' ');
    }

    /**
     * Handle card number change
     */
    handleCardNumberChange(event) {
        // Update display value immediately
        this.displayCardNumber = event.target.value;
        
        // Store raw value (digits only)
        let rawValue = event.target.value.replace(/\s/g, '').replace(/\D/g, '');
        rawValue = rawValue.substring(0, 16);
        
        this.internalCardData = {
            ...this.internalCardData,
            cardNumber: rawValue
        };
        this.dispatchChangeEvent();
    }

    /**
     * Handle expiration date change
     */
    handleExpirationChange(event) {
        let value = event.target.value;
        
        // Auto-format as MM/YY
        value = value.replace(/\D/g, ''); // Remove non-digits
        if (value.length >= 2) {
            value = value.substring(0, 2) + '/' + value.substring(2, 4);
        }
        
        this.internalCardData = {
            ...this.internalCardData,
            expirationDate: value
        };
        
        this.dispatchChangeEvent();
    }

    /**
     * Dispatch change event to parent
     */
    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: this.getPaymentData(),
            bubbles: false,
            composed: false
        }));
    }

    /**
     * @api Get payment data
     */
    @api
    getPaymentData() {
        // Parse expiration date
        let expirationMonth = '';
        let expirationYear = '';
        
        if (this.internalCardData.expirationDate) {
            const parts = this.internalCardData.expirationDate.split('/');
            if (parts.length === 2) {
                expirationMonth = parts[0];
                expirationYear = parts[1].length === 2 ? '20' + parts[1] : parts[1];
            }
        }

        return {
            data: {
                cardNumber: this.internalCardData.cardNumber,
                expirationDate: this.internalCardData.expirationDate,
                expirationMonth: expirationMonth,
                expirationYear: expirationYear
            }
        };
    }

    /**
     * @api Check validity
     */
    @api
    checkValidity() {
        const inputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                isValid = false;
            }
        });
        
        // Additional validation for card number (Luhn algorithm)
        if (this.cardData.cardNumber && !this.validateCardNumber(this.cardData.cardNumber)) {
            isValid = false;
        }
        
        return isValid;
    }

    /**
     * Validate card number using Luhn algorithm
     */
    validateCardNumber(number) {
        const digits = number.replace(/\D/g, '');
        if (digits.length < 13 || digits.length > 19) {
            return false;
        }

        let sum = 0;
        let isEven = false;
        
        for (let i = digits.length - 1; i >= 0; i--) {
            let digit = parseInt(digits[i], 10);
            
            if (isEven) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }
            
            sum += digit;
            isEven = !isEven;
        }
        
        return sum % 10 === 0;
    }

    /**
     * @api Report validity
     */
    @api
    reportValidity() {
        const inputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });
        return isValid;
    }

    
}