//Age Off 14
import { Signature } from "./Signature";

//Age Off 14
export function Template47(FirstName,OldestMemberName,OldestMemberBirthdate,MonthlyContribution,AgesUpDraftDate,NextContributionInSixtyDays,imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p><br>';
    body += '<p><p>One last reminder about an upcoming change to your Monthly Contribution Amount! Your current Monthly Contribution Amount of $'+MonthlyContribution +' will change to $'+  (NextContributionInSixtyDays != null ?NextContributionInSixtyDays : '')+' and will be reflected in your membership beginning on '+(AgesUpDraftDate != null ?AgesUpDraftDate : '')+'.</p> </p><br>';
    body += '<p><p>Have questions about this change? Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>.</p><br>';
    body += '<p>Thank you,</p>';

    body += Signature(imageURLs)

    return body;
}