import { Signature } from "./Signature";

//Closing Cancelation Request MEMBERS ONLY
export function Template17(FirstName, imageURLs) {
    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">Hello ' + FirstName + ',</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">Please know we are closing your request to cancel as we have made several attempts to reach you with no response. We are happy you have decided to stay with WeShare Healthcare by UHSM and greatly value you as a member. If you do still wish to cancel, please complete and sign the cancellation form and we will process it as soon as possible. <strong>Please know until your signed cancellation form is received your membership will remain active and continue to draft your monthly sharing contribution.</strong></span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span style="color:black;">&nbsp;or at 1-800-900-8476.</span></p>';
   
    body += Signature(imageURLs)


    return body;
}