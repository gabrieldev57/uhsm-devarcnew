import { Signature } from "./Signature";

//Age 26 Notice
export function Template14(firstName, fullName, imageURLs) {
    let body = '';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hi ' + firstName + ',</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thank you for trusting WeShare with your family&apos;s health and wellness needs!</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate '+fullName+' will soon exceed the program age limits (age 26) within your current family Sharing Program.</span></p>';	
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Adjusting your current Sharing Program will only take a few minutes, and we can discuss individual enrollment options for '+firstName+'. <b>Please note that these changes must be implemented before '+firstName+'&apos;s eligibility expires to avoid any gaps in sharing and/or re-enrollment fees.</b></span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Removal of any dependent(s) may apply changes to your current membership program, so please contact Member Services by phone at (800) 900-8476 or respond to this email as soon as possible.</span></p>';
	body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thanks for being a valuable Member of the WeShare community, and we look forward to serving you for many years to come.</span></p>';	

    body += Signature(imageURLs)

    return body;
}