import { Signature } from "./Signature";

//UHSM (SMART): Cancelled due to no contribution
export function Template29(FirstName, planName, imageURLs,ContractInactiveDate,ContractStatus) {
    let body = '';

    body += '<table style="border: none;">';
    body += '  <tbody>';
    body += '      <tr>';
    body += '        <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Hello ' + FirstName + ',</span></p>';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Your  ' + planName + ' membership has been cancelled'+ ((ContractInactiveDate && ContractStatus != 'Voided')? (' effective '+ ContractInactiveDate + ' because we did not receive  your monthly contribution.'):(' as never active because we did not receive your initial application fee and/or monthly contribution.'))+'</span></p>';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>If you have any additional questions, please do not hesitate to contact us at <span style="line-height:107%;color:black;"><a href="mailto:Members@weshare.org">Members@weshare.org</a></span> or at 1-800-900-8476.</span></p><br>';

    body += Signature(imageURLs)

    return body;
}