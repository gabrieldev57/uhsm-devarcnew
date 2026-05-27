//Age Off 30
import { Signature } from "./Signature";

//Age Off 30
export function Template46(FirstName,AgeUp,OldestMemberBirthdate,AgesUpEffectiveDate,imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p><br>';
    body += '<p><p>This is a reminder that your Monthly Contribution Amount will be changing soon. With your upcoming '+ AgeUp +' birthday on '+ OldestMemberBirthdate +', your membership is moving into a new age bracket and your new Monthly Contribution Amount is effective on '+AgesUpEffectiveDate+'.</p></br>';
    body += '<p><p>Our Member Services team is available to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>. </p><br>';
    body += '<p>Thank you,</p><br>';

    body += Signature(imageURLs)

    return body;
}