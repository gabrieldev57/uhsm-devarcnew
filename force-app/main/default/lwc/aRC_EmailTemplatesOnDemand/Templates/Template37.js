//Onboarding Attempt follow up
import { Signature } from "./Signature";

export function Template37(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;"><span>Dear ' + FirstName + ',</span></p>';
    body += '<p>Sorry we missed you! We are following up with you about your onboarding process with WeShare. We recently tried to reach out to discuss the program benefits, perks, and how to successfully use your program, but were unable to connect with you.</p><br>';
    body += '<p><p>We understand how important it is for you to have a seamless experience and not miss out on any benefits, so we would like to schedule another call with you as soon as possible. It is essential that we connect with you to ensure you are onboarded correctly and receive all the program benefits you deserve.</p> </p><br>';
    body += '<p><p>When you get a chance, reply to this email with the best time and date to chat and we can set up a call to complete your onboarding process. I will also try calling you again in the next couple of days.</p> </p><br>';
    body += '<p><p>We look forward to connecting with you soon!</p> </p><br>';
    body += '<p>Best Regards,</p>';
    body += '<p>Your Onboarding Specialist</p>';

    body += Signature(imageURLs)

    return body;
}