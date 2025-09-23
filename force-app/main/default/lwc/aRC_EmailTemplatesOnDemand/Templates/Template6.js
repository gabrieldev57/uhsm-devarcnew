import { Signature } from "./Signature";
//UHSM: Initial Payment Decline
export function Template6(firstName, memberId, planName, paymentMethod, paymentLast4, imageURLs) {

    let body = '';

    body += '<p style="margin-top:0in; margin-bottom:8.0pt;">Dear ' + firstName + ',</p><br>';

    body += '<p style="margin-top:0in; margin-bottom:8.0pt;">' +
        'Our records currently indicate that your initial contribution was declined for your WeShare membership. ' +
        '<span style="color:red;"><strong>If your contribution is not received, your membership will be cancelled.</strong></span>' +
        '</p><br>';

    body += '<p style="margin-top:0in; margin-bottom:8.0pt;">' +
        'Please provide us with the updated payment information via the DocuSign form, sent in a separate email, to ensure your Sharing Program is activated. Once you complete the form, your membership will be activated on your selected effective date. You may also call us directly at 1-800-900-8476 with any questions.' +
        '</p><br>';

    body += '<p style="margin-top:0in; margin-bottom:8.0pt;">' +
        'Thanks for being a valuable member of the WeShare community!' +
        '</p>';

    body += Signature(imageURLs);


    return body;
}