//Application Denial Email Template
import { SignatureProcessing } from "./SignatureProcessing";

export function Template53(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hi ' + FirstName + ',</p>';
    body += '<p>We appreciate your interest in the WeShare program. ';
    body += 'After careful review of your application, we regret to inform you that your application has been denied at this time due to medical history. ';
    body += 'Although we are unable to provide specific details, we can send you a copy of your medical report to you by certified mail. ';
    body += 'If this is something you would like, please reach out via email to&nbsp;<a href="mailto:processing@uhsm.org"><span style="color:blue;">processing@uhsm.org</span></a>.</p><br>';
    body += '<p>We genuinely value your interest in WeShare Healthcare by UHSM and want to assure you that our team continuously evaluates and updates our eligibility criteria. ';
    body += 'We encourage you to consider reapplying in the future. ';
    body += 'Thank you again for considering WeShare and we wish you all the best in your health and well-being.</p><br>';

    body += SignatureProcessing(imageURLs)

    return body;
}