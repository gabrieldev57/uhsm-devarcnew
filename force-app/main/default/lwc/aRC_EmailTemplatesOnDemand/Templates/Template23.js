import { Signature } from "./Signature";

//UHSM (A.I.D.D) Cancellation Confirmation
export function Template23(FirstName, AiddPlanName,ContractInactiveDate, imageURLs,ContractStatus) {
    let body = '';

    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;"><span>Dear ' + FirstName + ',</span></p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>We&apos;re sorry to see you go! This email is confirmation that your WeShare Healthcare by UHSM membership &nbsp;</span><strong><span>' + AiddPlanName + '&nbsp;</span></strong><span>has been cancelled'+ (ContractInactiveDate && ContractStatus != 'Voided'? (' as of '+ ContractInactiveDate +'.') : (' as never active.'))+'<br>&nbsp;<br>You will not incur any further charges. Please contact us if you feel you have received this notification in error.</span></p><br>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>If you have any additional questions, please do not hesitate to contact us at <span style="line-height:107%;color:black;"><a href="mailto:Members@weshare.org">Members@weshare.org</a></span> or at 1-800-900-8476.</span></p><br>';

    body += Signature(imageURLs)

    return body;
}