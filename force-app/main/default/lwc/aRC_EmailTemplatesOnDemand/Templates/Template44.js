import { Signature } from "./Signature";

//Cancel Request Pending follow up working on solution update
export function Template44(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Dear ' + FirstName + ',</p>';
    body += '<p>We hope this email finds you well. We are reaching out to you about your recent cancellation request for your WeShare Healthcare by UHSM membership, which we discussed over the phone and/or email. We are still working hard to find a solution to your issue and remain committed to resolving this quickly and efficiently.</p><br>';
    body += '<p><p>Our team has been reviewing your case carefully and is exploring all available options to ensure that any concerns or issues you have are addressed promptly and effectively. UHSM strives to find a solution that meets and exceeds your expectations. We hope to continue serving you as a valued member of the UHSM family for many years. </p> </p><br>';
    body += '<p><p>We understand that your experience thus far may not have met your expectations, and we sincerely apologize for any inconvenience or frustration that you have experienced. Please know that we here at UHSM value you and strive to do everything possible to correct the issue. </p> </p><br>';
    body += '<p><p>Thank you for your patience and understanding. Please contact us anytime to discuss this issue further.</p> </p><br>';
    body += Signature(imageURLs)

    return body;
}