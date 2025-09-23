import { Signature } from "./Signature";
//UHSM: APROVED-MP Network Access
export function Template19(FirstName, PrimaryName, CountOfDependents, MedicalPlanName, MemberID, ContractEffectiveDate, MonthlyContribution, InitialContribution, ChargeDate, imageURLs) {
    let body = '';

    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">Hello ' + FirstName + '!</span></p><br>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">Welcome to the WeShare family, a caring community dedicated to keeping you healthy, happy, and in control of your well-being. We&apos;re so glad to have you with us!</span></p><br>';
    body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">Please see below for important details of your WeShare Access membership:</span></p>';
    body += '<table style="border-collapse:collapse;border:none;">';
    body += '	<tbody>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-left: 1pt solid windowtext;border-bottom: none;border-right: none;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;"><br></td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-left: none;border-bottom: none;border-right: 1pt solid windowtext;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:white;">Membership Information</span></strong></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Primary Name</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>' + PrimaryName + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Program Level</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>' + CountOfDependents + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Company</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>WeShare</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Program Name</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>' + MedicalPlanName + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">ID Number</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span>' + MemberID + '</span></strong></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Effective Date</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>' +ContractEffectiveDate+ '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Initial Contribution (first month)</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>$' + InitialContribution + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Monthly Contribution (recurring)</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>$' + MonthlyContribution + '</span></p>';
    body += '			</td>';
    body += '		</tr>';
    body += '		<tr>';
    body += '			<td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '				<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><strong><span style="color:black;">Monthly Draft Date</span></strong></p>';
    body += '			</td>';
    body += '			<td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">'+ChargeDate+'<br></td>';
    body += '		</tr>';
    body += '	</tbody>';
    body += '</table>';



    body += '<p style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;"><u><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;color:black;">You will receive your welcome packet with your member ID card and program details within the next 30 days.&nbsp;</span></u></p>';
    body += '<p style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;"><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;color:#181818;">&nbsp;</span></p>';
    body += '<ul style="list-style:inside;margin-bottom:0in;margin-top:0in;" type="disc">';
    body += '    <li style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;font-size:15px;font-family:'+"Calibri"+',sans-serif;color:black;"><strong><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;border:none windowtext 1.0pt;padding:0in;">PHCS&reg;</span></strong><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;">&nbsp;<strong>PPO Network</strong></span><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;"><br> <span style="">At WeShare&trade;, we&rsquo;ve enlisted the <span style="border:none windowtext 1.0pt;padding:0in;">PHCS&reg; PPO Network,&nbsp;</span>the largest independent network in the country, with 1,200,000+ doctors, hospitals, and specialty providers. We know that the relationship between you and your doctor is vital, so we contracted with the PHCS doctors who deliver next-level care, take the time to really listen, and work with you as your partner toward better health. <strong>Find <em>and confirm</em> your <span style="border:none windowtext 1.0pt;padding:0in;">PHCS&reg;</span></strong> <strong>PPO Network Providers</strong>:&nbsp;</span><a href="https://www.weshare.org/find-a-provider/">https://www.weshare.org/find-a-provider/</a>&nbsp;</span></li>';
  
    body += '    <li style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;color:black;"><strong><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;border:none windowtext 1.0pt;padding:0in;">CVS MinuteClinic&reg;</span></strong><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;"></span><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;"><br> <span style="">We&rsquo;ve also partnered with CVS MinuteClinic&reg; to provide you access to in-person screening support and illness treatment. They can help you maintain your health with annual physicals, recommended screenings or vaccines, and treat illnesses if they arise. To find and access care - <a href="https://www.cvs.com/minuteclinic/clinic-locator/">Find a MinuteClinic&reg; Location </a>  </span></li>';
  
    body += '    <li style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;color:black;"><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;">Check out our <a href="https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.weshare.org%2Ffaq%2F&data=05%7C01%7Cvaughn.paladin%40arcsona.com%7C18608f9340a840de610f08dae9fb1bd4%7Ca558cde7946a49d6999b93069b28adf1%7C0%7C0%7C638079562034672581%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&sdata=gJZxoxtiHbhbxkhzlLCKW1%2FTxpil0olkQ4qiK0iwwYU%3D&reserved=0">Member FAQ</a><span style="">&nbsp;</span>to help address any immediate questions you may have. </span></p>';
    body += '</ul>';
    body += '<p style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;"><span style="font-size:13px;font-family:'+'"Segoe UI"'+',sans-serif;color:black;">&nbsp;</span></p>';
    body += '<p style="margin:0in;"><span style="color:black;">We are committed to helping you make the most of your WeShare health sharing membership, and our goal is to provide every Member with the care they deserve. For any questions, contact us at: <strong>1-800-900-8476 or&nbsp;</strong><a href="mailto:Members@weshare.org">Members@weshare.org</a></span></p>';
    body += '<p style="margin:0in;font-size:15px;font-family:'+"Calibri"+',sans-serif;"><strong><span style="color:black;">&nbsp;</span></strong></p>';

   
    body += Signature(imageURLs)
    return body;
}