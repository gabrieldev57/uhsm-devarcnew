import { Signature } from "./Signature";

//Payment CC Expiration – Metal
export function Template60(FirstName, imageURLs) {
    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ', </p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate that your credit card on file is expiring soon.</span></p>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Please respond to the email or call us at <strong>1-800-900-8476</strong> as soon as possible to provide your updated expiration date.</span></p>';
                    
    body += Signature(imageURLs)

    return body;
}