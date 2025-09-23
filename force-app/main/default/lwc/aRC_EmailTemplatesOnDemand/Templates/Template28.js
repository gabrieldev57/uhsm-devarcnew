import { Signature } from "./Signature";

//UHSM (SMART): Cancellation Confirmation
export function Template28(FirstName,planName,imageURLs,ContractInactiveDate,ContractStatus) {
    let body = '';

    body += '<table style="border: none;">';
    body += '  <tbody>';
    body += '      <tr>';
    body += '        <td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;"><span style="color:black;">Dear ' + FirstName + ',</span></p>';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">We&apos;re sorry to see you go! This email is confirmation that your WeShare Healthcare by UHSM membership <strong><span>' + planName + '&nbsp;</span></strong>has been cancelled'+ (ContractInactiveDate && ContractStatus != 'Voided'? (' as of '+ ContractInactiveDate +'.') : (' as never active'))+'.</span><span style="color:black;"><br><br></span><span style="color:black;">You will not incur any further charges. Please contact us if you have received this notification in error.</span></p><br>';
    body += '            <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>If you have any additional questions, please do not hesitate to contact us at <span style="line-height:107%;color:black;"><a href="mailto:Members@weshare.org">Members@weshare.org</a></span> or at 1-800-900-8476.</span></p><br>';

    body += Signature(imageURLs)

    return body;
}