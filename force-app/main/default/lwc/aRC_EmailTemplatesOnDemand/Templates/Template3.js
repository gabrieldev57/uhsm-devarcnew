import { Signature } from "./Signature";
//Payment Redraft Confirmation Email
export function Template3(FirstName, Last4Digits, NextTransactionDate, imageURLs) {
    let body = '';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hello ' + FirstName + ',</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Great news! Your contribution has been received and processed. <strong>Your membership is now current</strong>. Future contributions will be drafted from the payment method provided ending in <strong>'+ Last4Digits + '</strong>.' + (NextTransactionDate != null ? (' The next contribution will be drafted on ' + NextTransactionDate + '.</span></p>') : '');
    body += '<p><p><br>'
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</span></a><span>&nbsp;or 1-800-900-8476.</span></p><br>';
   
    body += Signature(imageURLs)

    return body;
}