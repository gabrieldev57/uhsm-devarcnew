//Age Off 60
import { Signature } from "./Signature";

//Age Off 60
export function Template45(FirstName,AgeUp,OldestMemberBirthdate,ProgramName, MonthlyContribution,AgesUpDraftDate,NextContributionInSixtyDays,imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p><br>';
    body += '<p><p>You\'ve got a celebration coming up! With your '+ AgeUp +' birthday on '+ OldestMemberBirthdate +', your membership is moving into a new age bracket. This means there\'s a change coming to your '+ ProgramName +' Monthly Contribution Amount. <span style="font-weight:bold;">There is no action required on your part.</span></p><br>';
    body += '<p><p>Your current Monthly Contribution Amount of $'+MonthlyContribution +' will change to $'+  (NextContributionInSixtyDays != null ?NextContributionInSixtyDays : '')+' and will be reflected in your membership beginning on '+(AgesUpDraftDate != null ?AgesUpDraftDate : '')+'.</p><br>';
    body += '<p><p>Our Member Services team is happy to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>. </p><br>';
    body += '<p>Thank you,</p>';

    body += Signature(imageURLs)

    return body;
}