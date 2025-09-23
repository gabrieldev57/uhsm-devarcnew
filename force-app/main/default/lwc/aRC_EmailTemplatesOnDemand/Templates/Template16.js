import { Signature } from "./Signature";

//Message Received
export function Template16(imageURLs) {
    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;line-height:107%;"><span style="line-height:107%;">Hi,</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;line-height:107%;"><span style="line-height:107%;">We&apos;re on it! Our team is working promptly to resolve your request. Please allow approximately 6-8 business days for an update. We appreciate your patience.</span></p>';
    // body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">&nbsp;</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span>&nbsp;or at 1-800-900-8476.</span></p>';

    body += Signature(imageURLs)

    return body;
}