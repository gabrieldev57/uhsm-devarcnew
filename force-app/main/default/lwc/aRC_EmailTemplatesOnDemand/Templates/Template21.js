import { Signature } from "./Signature";

//Payment Decline – Recurring Metal 
export function Template21(FirstName, imageURLs) {
    let body = '';

    body += '<table style="border: none;">';
    body += '  <tbody>';
    body += '      <tr>';
    body += '        <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '            <table style="border: none;">';
    body += '              <tbody>';
    body += '                  <tr>';
    body += '                    <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '                        <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%:"><span><br>Dear ' + FirstName + ',</span></p>';
    body += '                        <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Our records currently indicate that your current month\'s contribution was declined for your WeShare membership.</p>';
    body += '                        <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:"><Strong>If your contribution is not received, your membership will be cancelled, effective on the date of your last sharing contribution.</Strong></p>';
    body += '                        <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Please fill out the DocuSign form sent separately, or reply to this email or call us <Strong>1-800-900-8476</Strong> to provide your updated payment method.</p>';
    body += '                        <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">A charge can be declined for a variety of reasons. For more information on why the charge was declined, please contact your bank or the bank that issued your card.</p>';

    body += Signature(imageURLs)

    return body;
}