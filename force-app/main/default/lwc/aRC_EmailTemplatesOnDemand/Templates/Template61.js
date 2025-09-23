import { Signature } from "./Signature";

//Withdraw Confirmation – Generic
export function Template61(FirstName, imageURLs) {
    let body = '';

    body += '<table style="border: none;">';
    body += '	<tbody>';
    body += '		<tr>';
    body += '			<td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">Dear ' + FirstName + ',</span></p>';
		body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">We&apos;re sorry to see you go! Your WeShare membership application has been withdrawn. You will not incur any further charges.</span></p>';
		body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">If you have received this notification in error or have any additional questions, please contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span style="color:black;">&nbsp;</span><span style="color:black;">or at 1-800-900-8476.</span></p><br>';
 
    body += Signature(imageURLs)

    return body;
}