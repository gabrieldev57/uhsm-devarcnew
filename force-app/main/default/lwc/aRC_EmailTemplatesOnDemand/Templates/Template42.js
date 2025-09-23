import { Signature } from "./Signature";

//Cancelation Request Final Reach out 
export function Template42(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Dear ' + FirstName + ',</p>';
    body += '<p>We hope this email finds you well. We are contacting you regarding your recent request to cancel your WeShare Healthcare by UHSM membership.</p><br>';
    body += '<p><p>While UHSM has attempted to reach you several times through various means of communication, our attempts have failed. This email is your confirmation that your membership will remain active until we hear from you. </p> </p><br>';
    body += '<p><p>UHSM understands and respects your decision if you have decided to cancel your membership with us. However, we would like to take this opportunity to emphasize the benefits of being a member of UHSM and would love the chance to continue our relationship with you.</p> </p><br>';
    body += '<p><p>UHSM greatly values your membership with us and would be happy to address any concerns or issues that you may have. Please contact us at your earliest convenience to discuss your membership status.</p> </p><br>';
    body += '<p>Thank you for being part of the WeShare Healthcare by UHSM Family!</p>'; 
    body += Signature(imageURLs)

    return body;
}