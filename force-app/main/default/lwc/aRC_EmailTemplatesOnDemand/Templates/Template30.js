import { Signature } from "./Signature";

//UHSM (SMART) Initial Payment Decline
export function Template30(FirstName, SmartPlanName, NextTransactionDate, imageURLs) {
    let body = '';

    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Dear ' + FirstName + ',</p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Our records currently indicate that your initial contribution was declined for your WeShare Healthcare by UHSM membership.</p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Please provide us with the updated payment information using the attached form so there will be no interruption to your membership. Please complete the form and return via email to <a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</a> or fax to <u>Attn: Billing at 1-888-858-3315</u>. You may also call us directly at 1-800-900-8476.</p>';
    body += '<p><strong>Program</strong><strong>:</strong> ' + SmartPlanName + '</p>';
    body += '<p><strong>Contribution Due:</strong> ' + NextTransactionDate + '</p><br>';
    body += '<p style="color:red;margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;"><strong>If your contribution is not received, your membership will be cancelled as never active.</strong></p>';
    body += '<p>A charge can be declined for a variety of reasons. For more information on why the charge was declined, please contact your bank or the bank that issued your card.</p>';

    body += Signature(imageURLs)

    return body;
}