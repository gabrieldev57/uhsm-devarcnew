//Onboarding final Attempt 
import { Signature } from "./Signature";

export function Template38(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;"><span>Dear ' + FirstName + ',</span></p>';
    body += '<p>Sorry we missed you! We’ve been trying to contact you regarding the completion of your onboarding with WeShare, and I want to make sure you have everything you need to get all the benefits and perks of being a Member. </p><br>';
    body += '<p><p>Please let us know a good time and date to connect with you via email at <a href="mailto:Members@weshare.org">Members@weshare.org</a>. </p> </p><br>';
    body += '<p><p>We look forward to chatting with you soon!</p> </p><br>';
    body += '<p>Best Regards,</p>';
    body += '<p>Your Onboarding Specialist</p>';
    body += Signature(imageURLs)

    return body;
}