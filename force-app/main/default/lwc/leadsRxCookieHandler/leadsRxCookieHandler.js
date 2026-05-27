import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin'; // Import the mixin

export default class LeadsRxCookieHandler extends OmniscriptBaseMixin(LightningElement) {

    @api cookieName = '_lab'; // Cookie to retrieve

    connectedCallback() {
        // Retrieve the cookies when the component is loaded
        this.getCookieFromEvent();
    }

    // Function to dispatch event to get cookies from the Head Markup
    getCookieFromEvent() {
        const getCookieEvent = new CustomEvent('getCookies', {
            bubbles: true,
            composed: true,
            detail: { value: "" }  // Placeholder to receive cookies
        });

        this.dispatchEvent(getCookieEvent);

        // Access the cookies from the returned detail value
        const allCookies = getCookieEvent.detail.value;
        console.log("All cookies: ", allCookies);

        this.getCookie(this.cookieName, allCookies);
    }

    // Function to parse the specific cookie value
    getCookie(cookieName, allCookies) {
        let cookieValue = "";

        if (allCookies) {
            let cookieArray = allCookies.split(';');
            cookieArray.forEach((cookie) => {
                let trimmedCookie = cookie.trim();
                if (trimmedCookie.startsWith(`${cookieName}=`)) {
                    cookieValue = trimmedCookie.substring(cookieName.length + 1);
                }
            });
        }

        // If the cookie is found, add it to OmniScript's data JSON
        if (cookieValue) {
            console.log("Retrieved Cookie Value: ", cookieValue);
            this.updateOmniScriptData({ cookieId: cookieValue }); // Pass cookieId using omniApplyCallResp
        } else {
            console.error("Cookie not found or value is empty");
        }
    }

    // Function to update OmniScript's JSON with cookie data
    updateOmniScriptData(data) {
        if (this.omniApplyCallResp) {
            // Use omniApplyCallResp to apply the cookie ID to the OmniScript’s data JSON
            this.omniApplyCallResp(data);  // This will merge the data with existing OmniScript data
            console.log("Updated OmniScript Data JSON with:", data);
        } else {
            console.error("omniApplyCallResp method not available.");
        }
    }
}