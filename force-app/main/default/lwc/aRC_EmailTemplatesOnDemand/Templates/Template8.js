import { Signature } from "./Signature";

//Payment Method Update Confirmation
export function Template8(FirstName, Last4Digits, NextTransactionDate, imageURLs) {
    let body = '';

    body += '<div style="margin: 0px; padding: 0px; user-select: text; -webkit-user-drag: none; -webkit-tap-highlight-color: transparent; overflow: visible; cursor: text; clear: both; position: relative; direction: ltr; color: rgb(0, 0, 0); letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(255, 255, 255); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;">';
    body += '    <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hello ' + FirstName + ',</span></p>';
    body += '    <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Great news! Your updated contribution has been processed. All future contributions will be drafted from the new card provided ending in ' + Last4Digits + '. The next contribution will draft on ' + (NextTransactionDate != null ?(' The next contribution will draft on ' + NextTransactionDate + '.</span></p>'):'');
    body += '    <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thanks for being a valuable member of the WeShare community!</span></p>';


    body += Signature(imageURLs)

    return body;
}