import { Signature } from "./Signature";

export function Template56(FirstName, imageURLs) {

    return `
        <body style="font-family: Arial, sans-serif; color: #333;">
            <p style="margin: 10px 0;">Hello ${FirstName},</p>
            <p style="margin: 10px 0;">
                Our records indicate that lab work has only been completed by one Member. Both the primary Member and spouse must individually qualify to receive the healthy discount. In order to avoid delays in reviewing your results, please ensure the second Member completes their blood work as soon as possible.
            </p>
            <p style="margin: 10px 0;">
                Please find attached the lab requisition form and a reminder on the application process below.
            </p>
            <ul style="padding-left: 20px; list-style-type: disc;">
                <li style="list-style-type: disc; margin-bottom: 10px;">
                    Schedule an appointment with your closest LabCorp.
                    <ul style="padding-left: 20px; list-style-type: circle;">
                        <li style="list-style-type: circle; margin-bottom: 10px;">LabCorp Locations:
                            <ul style="padding-left: 20px; list-style-type: square;">
                                <li style="list-style-type: square; margin-bottom: 10px;"><a href="https://www.labcorp.com/labs-and-appointments" target="_blank" style="color: #0056b3; text-decoration: none;">Labs Near You: No Appointment Needed for Testing | Labcorp</a></li>
                            </ul>
                        </li>
                    </ul>
                </li>
                <li style="list-style-type: disc; margin-bottom: 10px;">Remember to take the form with you to your appointment!</li>
                <li style="list-style-type: disc; margin-bottom: 10px;"><b>Do not</b> use your WeShare ID for billing. Please ensure that LabCorp bills to the account listed on the lab order.</li>
                <li style="list-style-type: disc; margin-bottom: 10px;">After your appointment, your test results will be sent directly from the lab for physician review.</li>
                <li style="list-style-type: disc; margin-bottom: 10px;">Results can take between 2 - 4 business days.</li>
                <li style="list-style-type: disc; margin-bottom: 10px;">A member of our team will call you to share the final determination.</li>
            </ul>
            <p style="margin: 10px 0;">
                If you have any questions about this process, please reach out to Member Services at <a href="mailto:members@weshare.org" style="color: #0056b3; text-decoration: none;">members@weshare.org</a> or call 800-900-8476.
            </p>
        </body>
        ${Signature(imageURLs)}
    `;
}