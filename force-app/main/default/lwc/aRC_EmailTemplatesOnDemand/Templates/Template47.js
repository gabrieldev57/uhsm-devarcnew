//Age Off 14
import { Signature } from "./Signature";

//Age Off 14
export function Template47(FirstName,OldestMemberName,OldestMemberBirthdate,MonthlyContribution,AgesUpDraftDate,NextContributionInSixtyDays,imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hello ' + FirstName + ',</p><br>';
    body += '<p><p>This is a final reminder for an upcoming change to your monthly WeShare membership sharing amount due to '+ OldestMemberName +' birthday on '+ OldestMemberBirthdate +', moving your membership into a new age bracket. <span style="font-weight:bold;">There is no action required on your part.</span></p><br>';
    body += '<p><p>Your current monthly sharing amount of $'+MonthlyContribution +'  will change to $'+  (NextContributionInSixtyDays != null ?NextContributionInSixtyDays : '')+', and will be reflected in your monthly sharing amount moving forward beginning in '+(AgesUpDraftDate != null ?AgesUpDraftDate : '')+'.</p> </p><br>';
    body += '<p><p>Our Member Services team is available and happy to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at (800) 900-UHSM (8476) or send an email to <a href="memberservices@uhsm.org">memberservices@uhsm.org</a>. </p> </p><br>';
    body += '<p>Thank you,</p>';

    body += Signature(imageURLs)

    return body;
}