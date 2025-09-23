import { Signature } from "./Signature";

export function Template51(FirstName, imageURLs) {
    return `
        <p style="margin: 10px 0;">Hi ${FirstName},</p>
        
        <p style="margin: 10px 0;">Thank you for submitting your labs for our Healthy Discount program. Unfortunately, your results did not meet our criteria and you are ineligible for the discount at this time.</p>
        
        <p style="margin: 10px 0;">Please find attached the healthy discount lab results criteria. If you are interested in obtaining or reviewing your results in depth with the reviewing physician, follow the instructions listed in the document.</p>
        
        <p style="margin: 10px 0;">You can also elect to participate in a wellness program offered through Integrative Health Direct Primary Care and reapply for the discount every 90 days. To learn more about the wellness program, follow the instructions in the document to connect with Integrative Health DPC.</p>
        
        <p style="margin: 10px 0;">If you have any questions, please contact Member Services at <a href="mailto:members@weshare.org">members@weshare.org</a> or call 800.900.8476.</p>

        ${Signature(imageURLs)}
    `;
}