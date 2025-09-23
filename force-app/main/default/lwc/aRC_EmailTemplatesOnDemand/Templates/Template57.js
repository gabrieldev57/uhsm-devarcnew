import { Signature } from "./Signature";

export function Template57(FirstName, imageURLs) {
    return `
        <p style="margin: 10px 0;">Hi ${FirstName},</p>
        
        <p style="margin: 10px 0;">
        Please find attached the requisition form we discussed to complete your
         lab work so we can continue with your WeShare application. I have included instructions below.</p>

        <p style="margin: 10px 0;">
        <b>Obtaining lab work to be considered for the program</b></p>
				<p style="margin: 10px 0;">
        <ul>
        <li>Download the attached form, print it out, and add your information to the form.</li>
        <li>Schedule an appointment with your closest LabCorp or Quest Diagnostics.
         <ul><li><p>Quest Diagnostics Locations:
          <ul><li><a href="http://www.questdiagnostics.com/locations" data-inline-card="" data-card-data="">
        http://www.questdiagnostics.com/locations</a></li></ul></li>
             <li>LabCorp Locations:
         <ul><li><a href="http://www.labcorp.com/labs-and-appointments" data-inline-card="" data-card-data="">
        http://www.labcorp.com/labs-and-appointments</a></li></ul></li>
         </ul>
        </li>
        <li>Remember to take the form with you to your appointment!</li>
        <li>After your appointment, your test results will be sent directly to UHSM so we can continue
         with your application review.</li>
        <li>Results can take between 2 - 4 business days.</li>
        <li>You will receive a written outcome with a final determination on your application.</li>
        </ul>
				</p>
        <p style="margin: 10px 0;">If you have any questions about this process,
         please reach out to Member Services at <a href="mailto:members@weshare.org">members@weshare.org</a> or call 800-900-8476.</p>

        ${Signature(imageURLs)}
    `;
}