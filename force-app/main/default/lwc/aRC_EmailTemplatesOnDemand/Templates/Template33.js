import { Signature } from "./Signature";

//Missed Callback , could not leave a voicemail email
export function Template33(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin:0in;"><span>Hello ' + FirstName + ',</span></p><br>';
    body += '<p style="margin:0in;"><span>Thanks for contacting us! We received your callback request but were unable to leave you a voicemail after attempting to contact you. Feel free to contact us at <span style="line-height:107%;color:black;"><a href="mailto:Members@weshare.org">Members@weshare.org</a></span> or at 1-800-900-8476</span> with a better date and time for us to chat.</span></p>';
    body += '<p style="margin:0in;"><span>&nbsp;</span></p>';
    body += '<p style="margin:0in;"><span>Thank you again for reaching out. Looking forward to speaking to you soon.</span></p>';
    body += '<p style="margin:0in;"><span>&nbsp;</span></p>';
   
    body += Signature(imageURLs)
    
    return body;
}