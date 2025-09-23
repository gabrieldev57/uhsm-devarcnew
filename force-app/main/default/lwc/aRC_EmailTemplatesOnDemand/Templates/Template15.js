import { Signature } from "./Signature";

//Medical Review Follow Up APPROVED /Reprocessed 
export function Template15(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">Hello&nbsp;' + FirstName + ',</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">This is a follow up to your initial medical review inquiry that you requested. The services have been re-processed, and you can expect an updated explanation from our team shortly. Thank you for being a WeShare Healthcare by UHSM member.</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">&nbsp;</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span>&nbsp;or at 1-800-900-8476.</span></p>';

    body += Signature(imageURLs)

    return body;
}