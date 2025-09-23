import { Signature } from "./Signature";

//UHSM (A.I.D.D): Cancelled due to no contribution
export function Template24(FirstName, AiddPlanName, ContractInactiveDate, imageURLs,ContractStatus) {
    let body = '';

    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Hello ' + FirstName + ',</span></p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">Your ' + AiddPlanName + ' membership has been cancelled'+ ((ContractInactiveDate && ContractStatus != 'Voided')? (' effective '+ ContractInactiveDate + ' because we did not receive your monthly contribution.'):(' as never active because we did not receive your initial application fee and/or monthly contribution.'))+'</span></p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;">If you have any additional questions, please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org">Members@weshare.org</span></a>&nbsp;or at 1-800-900-8476.</span></p>';

    body += Signature(imageURLs)

    return body;
}