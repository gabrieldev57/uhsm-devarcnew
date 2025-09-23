import { Signature } from "./Signature";
//Monthly Contribution Received
export function Template4(FirstName, MonthlyContribution, imageURLs) {
    let body = '';
    body += '<table style="border: none;">';
    body += '    <tbody>';
    body += '        <tr>';
    body += '            <td style="padding:.75pt .75pt .75pt .75pt;">';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hi ' + FirstName + ',</span></p>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thank you for this month&apos;s contribution of&nbsp;</span><strong><span>$' + MonthlyContribution + '</span></strong><span>&nbsp;towards member sharing. Please allow up to 1-5 additional business days for the contribution to be withdrawn from your account.</span></p><br>';
    body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thanks for being a Member of the WeShare community!</span></p><br>';

   
    body += Signature(imageURLs)

    return body;
}