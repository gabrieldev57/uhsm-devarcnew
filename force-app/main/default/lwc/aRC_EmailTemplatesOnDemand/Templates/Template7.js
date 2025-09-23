import { Signature } from "./Signature";

//Demographic Update Notice
export function Template7(FirstName, imageURLs) {

    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ',</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Your information has been updated. If you have any additional questions, please do not hesitate to contact us at </span><a href="mailto:Members@weshare.org"><span>Members@weshare.org</span></a><span>&nbsp;or at 1-800-900-8476.</span></p><br>';
    body += Signature(imageURLs)

    return body;
}