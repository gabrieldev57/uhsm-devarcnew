import { Signature } from "./Signature";

//Withdraw Confirmation – No First Month Contribution
export function Template10(FirstName, imageURLs) {
    
    let body = '';
    
    body += '<table style="border: none;">';
    body += '    <tbody>';
    body += '        <tr>';
    body += '            <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hello ' + FirstName + ',</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Your WeShare membership has been cancelled because we did not receive your initial monthly contribution.</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>We&apos;d love to help get your membership back on track! Please contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span>&nbsp;or at 1-800-900-8476 so that our team can help you get the amazing benefits and care found in our Sharing Programs.</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>We look forward to hearing from you!</span></p>';
    body += Signature(imageURLs)

    return body;
    
}