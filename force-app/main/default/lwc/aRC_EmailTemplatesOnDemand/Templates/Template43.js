//OffBoarding
import { Signature } from "./Signature";

//Initial + Follow UP Cancelation Request Follow Up 
export function Template43(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Dear ' + FirstName + ',</p>';
    body += '<p>Thank you, for reaching out to us. We are sorry to hear that you are considering canceling your membership. WeShare Healthcare by UHSM has tried to reach out to you at the phone number provided but has yet to be able to connect with you.</p><br>';
    body += '<p><p>Please contact our Member Offboarding Team at <a href="mailto:Members@weshare.org">Members@weshare.org</a> with a convenient time and date to connect with you. Member Services will also try contacting you again in a few days. </p> </p><br>';
     body += '<p><p>We look forward to hearing from you soon and hope to find a solution that will allow us to continue serving you as a valued member.</p> </p><br>';
    body += '<p>Thank you for being part of the WeShare Healthcare by UHSM family. We hope to hear from you soon.</p>';

    body += Signature(imageURLs)

    return body;
}