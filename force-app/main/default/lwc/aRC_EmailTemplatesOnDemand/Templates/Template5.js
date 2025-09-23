import { Signature } from "./Signature";

//Monthly Contribution Notice
export function Template5(FirstName, monthlyContributionDate, monthlyContributionAmount, imageURLs) {

    let body = '';

    body += '  <p dir="ltr"><span>';
    body += '  Hi ' + FirstName + ',';
    body += '  </span></p><br>';
    body += '  <p dir="ltr">';
    body += '      Your next monthly contribution is due in 3 days. No action is required as it will be automatically withdrawn from the account we have on file.';
    body += '  </p><br>';
    body += '  <p dir="ltr">';
    body += '      <strong>Monthly Contribution Due Date:</strong> ' + monthlyContributionDate;
    body += '      <br>';
    body += '      <strong>Monthly Contribution Amount:</strong> $' + monthlyContributionAmount;
    body += '  </p><br>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thanks for being a Member of the WeShare community!</span></p><br>';

    body += Signature(imageURLs)


    return body;
}