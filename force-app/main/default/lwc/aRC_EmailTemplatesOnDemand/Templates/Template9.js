import { Signature } from "./Signature";

//Payment CC Expiration – WeShare
export function Template9(FirstName, Last4Digits, imageURLs) {
    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ', </p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate that your credit card on file ending in ' + Last4Digits + ' is expiring soon.</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Please update your payment information in the member portal at <a href="https://uhsm.my.site.com/members/s/payment-information">https://uhsm.my.site.com/members/s/payment-information</a>.</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>You may also contact us directly at <a href="mailto:Members@weshare.org">Members@weshare.org</a> or call us <strong>1-800-900-8476</strong> to provide your updated expiration date.</span></p>';
                
    body += Signature(imageURLs)

    return body;
}