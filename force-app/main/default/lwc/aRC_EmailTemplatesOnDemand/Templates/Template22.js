import { Signature } from "./Signature";

//UHSM (A.I.D.D): Approval Email
export function Template22(Name,PrimaryName, CountOfDependents, AiddPlanName, MemberID, ContractEffectiveDate, AIDDPlanPrice, ChargeDate, imageURLs) {
    
    let body = '';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">Dear ' + Name.substring(0,Name.indexOf(' ')) + ',</span></p><br>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">Please see below for the status of your membership:</span></p>';
    body += '<table style="border-collapse:collapse;border:none;">';
    body += '	<tbody>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-left: 1pt solid windowtext;border-bottom: none;border-right: none;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;"><br></td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-left: none;border-bottom: none;border-right: 1pt solid windowtext;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:white;">Client Information</span></strong></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Primary Name</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + PrimaryName + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><strong><span style="color:black;">Benefit Level</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><span>' + CountOfDependents + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Company</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>UHSM</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Program Name</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + AiddPlanName + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">ID Number</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + MemberID + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><strong><span style="color:black;">Effective Date</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;"><span style="line-height:107%;">' +ContractEffectiveDate+ '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Monthly Contribution</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + AIDDPlanPrice + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Monthly Draft Date</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + ChargeDate + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Client Action Item(s)</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>Please allow 5-7 business days to receive your welcome letter.</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '	</tbody>';
    body += '</table>';
    body += '<hr>';
    body += '<p><span style="color:black;">We are committed to helping you make the most of your WeShare health sharing membership, and our goal is to provide every Member with the care they deserve. For any questions, contact us at: <strong>1-800-900-8476 or&nbsp;</strong><a href="mailto:Members@weshare.org">Members@weshare.org</a></span></p>';
   

    body += Signature(imageURLs)

    return body;
}