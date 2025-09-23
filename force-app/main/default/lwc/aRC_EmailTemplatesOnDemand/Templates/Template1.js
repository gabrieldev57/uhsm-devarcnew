import { Signature } from "./Signature";
//UHSM Confirmation Notice
export function Template1(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hello ' + FirstName + ',</p>';
    body += '<p>Thank you for reaching out to us. As requested, a welcome packet and/or ID Card has been resent. You should receive it within the next 10 business days.</p><br>';
    body += '<p>If you have any additional questions, please do not hesitate to contact us at <a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</a>&nbsp;or at 1-800-900-8476.</p><br>';
    body += Signature(imageURLs)

    return body;
}