import { Signature } from "./Signature";

//Age 26 Notice
export function Template14(recipientName, firstName, fullName, imageURLs) {
    let body = '';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hi ' + recipientName + ',</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thank you for trusting WeShare with your family\'s health and wellness needs!</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate ' + fullName + ' will soon exceed your Sharing Program\'s age limits (age 26).</span></p>';	
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>We need to adjust your current Sharing Program to reflect this change and discuss individual enrollment options for '+firstName+'. <b>Please note that these changes must be implemented before '+firstName+'\'s eligibility expires to avoid any gaps in sharing and/or re-enrollment fees.</b></span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Removal of any dependent(s) may apply changes to your current membership program, so please contact Member Services by phone at (800) 900-8476 or respond to this email as soon as possible.</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thanks for being a valuable Member of the WeShare community and we look forward to serving you in the future.</span></p>';	

    body += Signature(imageURLs)

    return body;
}