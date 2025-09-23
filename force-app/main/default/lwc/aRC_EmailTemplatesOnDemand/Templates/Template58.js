import { Signature } from "./Signature";

//Withdraw Confirmation – No App Fee
export function Template58(FirstName, imageURLs) {
    
    let body = '';
    
    body += '<table style="border: none;">';
    body += '    <tbody>';
    body += '        <tr>';
    body += '            <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hello ' + FirstName + ',</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Your WeShare application has been withdrawn because we did not receive your application fee.</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span>&nbsp;or at 1-800-900-8476.</span></p>';
    body += Signature(imageURLs)

    return body;
    
}