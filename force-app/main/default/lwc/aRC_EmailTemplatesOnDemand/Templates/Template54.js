import { Signature } from "./Signature";
//Member Google Review
export function Template54(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hello ' + FirstName + ',</p>';
    body += '<p>It was a pleasure assisting you today! If you have any additional questions, please let me know. I would greatly appreciate if you would be able to leave a review based on your experience with UHSM. This goes a long way with the company and helps with my performance reviews! </p><br>';
    body += '<p>Please click on this link, <a href="https://www.google.com/maps/place/WeShare+by+UHSM/@36.8433654,-76.2878385,17z/data=!3m1!4b1!4m6!3m5!1s0x89ba997330574051:0x5a3c9a8e2b556e5a!8m2!3d36.8433654!4d-76.2878385!16s%2Fg%2F11h04n59kx?entry=ttu"><span style="color:#0563C1;">Share Your Experience</a>.</p><br>';
    body += Signature(imageURLs)

    return body;
}