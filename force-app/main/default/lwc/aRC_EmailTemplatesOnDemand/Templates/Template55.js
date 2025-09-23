import { Signature } from "./Signature";

export function Template55(FirstName, imageURLs) {

    let body = ''
    body += '<p style="margin: 10px 0;">Hello ' + FirstName + ',</p>'
    body += '<p style="margin: 10px 0;">Please find attached the requisition form to complete your lab work to be considered for the healthy discount. We have included instructions below.</p>'
    body += '<h3 style="margin: 10px 0;">APPLYING FOR HEALTHY DISCOUNT</h3>'
    body += '<ul style="list-style-type:disc;margin-left:20px;">'
    body += '    <li style="margin: 10px 0;">Download the attached form, print it out, and add your information to the form.</li>'
    body += '    <li style="margin: 10px 0;">Schedule an appointment with your closest LabCorp or Quest Diagnostics.'
    body += '        <ul style="margin: 10px 0;">'
    body += '            <li style="list-style-type:circle;margin-left:20px;margin-bottom: 10px;">Quest Diagnostics Locations:'
    body += '                <ul>'
    body += '                    <li style="list-style-type:square;margin-left:20px;margin-bottom: 10px;"><a href="http://www.questdiagnostics.com/locations" target="_blank">www.questdiagnostics.com/locations</a></li>'
    body += '                </ul>'
    body += '            </li>'
    body += '            <li style="list-style-type:circle;margin-left:20px;margin-bottom: 10px;">LabCorp Locations:'
    body += '                <ul>'
    body += '                    <li style="list-style-type:square;margin-left:20px;margin-bottom: 10px;"><a href="http://www.labcorp.com/labs-and-appointments" target="_blank">www.labcorp.com/labs-and-appointments</a></li>'
    body += '                </ul>'
    body += '            </li>'
    body += '        </ul>'
    body += '    </li>'
    body += '    <li style="margin: 10px 0;">Remember to take the form with you to your appointment!</li>'
    body += '    <li style="margin: 10px 0;">After your appointment, your test results will be sent directly from the lab for physician review.</li>'
    body += '    <li style="margin: 10px 0;">Results can take between 2 - 4 business days.</li>'
    body += '    <li style="margin: 10px 0;">A member of our team will call you to share the final determination.</li>'
    body += '</ul>'
    body += '<p style="margin: 10px 0;"><strong>Note:</strong> Both the primary member and spouse must individually qualify to receive the discount. Each individual must qualify by the healthy blood test results. Children are exempt.</p>'
    body += '<p style="margin: 10px 0;">If you have any questions about this process, please reach out to Member Services at <a href="mailto:members@weshare.org">members@weshare.org</a> or call 800-900-8476.</p>'
    body += Signature(imageURLs)

    return body;
}