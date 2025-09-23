export function Signature(imageURLs) {

    let signature = '';
    signature += '<br>';
    signature += '<table style="border: none; border-collapse: collapse; margin-right: calc(57%); ">';
    signature += '	<tbody>';
    signature += '		<tr>';
    signature += '			<td rowspan="5" style="width: 26.1868%;border-right: 2px solid #cdd0d4; Padding: 10px;">';
    signature += '				    <img src='+imageURLs.WeShareUHSM+' style="width: 300px;"/>';
    signature += '			</td>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<p style="margin:0px";><strong>Member Services</strong></p>';
    signature += '			</td>';
    signature += '		</tr>';
    signature += '		<tr>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<p style="margin: 0;">1-800-900-8476</p>';
    signature += '			</td>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<a href="//www.weshare.org">www.weshare.org</a>';
    signature += '			</td>';
    signature += '		</tr>';
    signature += '		<tr>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<a href="mailto:Members@weshare.org">Members@weshare.org</a>';
    signature += '			</td>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<a href="https://www.facebook.com/wesharebyuhsm "><img src='+imageURLs.FacebookIcon+' ></a> <a href="https://www.twitter.com/weshare_by_uhsm "><img src='+imageURLs.TwitterIcon+'></a> <a href="https://www.instagram.com/weshare_by_uhsm"><img src='+imageURLs.InstagramIcon+'></a> <a href="https://www.linkedin.com/company/wesharebyuhsm"><img src='+imageURLs.LinkedinIcon+' ></a>';
    signature += '			</td>';
    signature += '		</tr>';
    signature += '		<tr>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<p style="margin:0px";>999 Waterside Drive, Ste. 2600</p>';
    signature += '			</td>';
    signature += '		</tr>';
    signature += '		<tr>';
    signature += '			<td style="width:178.1pt;padding:0in 5.4pt 0in 5.4pt;">';
    signature += '				<p style="margin:0px">Norfolk, Virginia 23510</p>';
    signature += '			</td>';
    signature += '		</tr>';
    signature += '	</tbody>';
    signature += '</table>';
    signature += '<br>';
    signature += '<p><span style=""><strong>IMPORTANT NOTE:</strong></span> The information contained in this transmission is considered to be privileged communications, and/or is Confidential Information intended for the sole use of individuals or entities named herein. If the Reader of this communication is not the intended recipient, you are hereby notified that any dissemination, distribution, or copy of this communication or the information contained herein is strictly prohibited. This E-mail is covered by the Electronic Communications Privacy Act, 18 U.S.C. sections 2510-2521 and is legally privileged.</p>';
    
    return signature;
    }