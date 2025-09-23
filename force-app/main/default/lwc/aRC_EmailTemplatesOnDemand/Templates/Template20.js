import { Signature } from "./Signature";

//UHSM Update Confirmation
export function Template20(FirstName, paymentMethod, paymentLast4, imageURLs) {
    let body = '';

    body += '<table style="border: none;">';
    body += '  <tbody>';
    body += '      <tr>';
    body += '        <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '            <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span><br>Hello ' + FirstName + ',</span></p>';
    body += '            <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Please be advised your contribution authorization has been received/processed. <strong><span style="color:#C0392B;">Your membership is now current</span></strong>. All ongoing contributions will draft from the account provided ending in <strong>' + paymentMethod + ' - xxxx' + paymentLast4 + '</strong>. The next contribution will draft on&nbsp;.</span></p>';
    body += '            <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:memberservices@uhsm.org"><span style="color:#0563C1;">memberservices@uhsm.org</span></a><span>&nbsp;or at 1-800-900-8476.</span></p>';
    body += '            <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Sincerely,</span></p>';

    body += Signature(imageURLs)

    return body;
}