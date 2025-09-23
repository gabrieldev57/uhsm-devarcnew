import { Signature } from "./Signature";

//UHSM Approved (Payment decline) MP Network
export function Template31(Name, PrimaryName, CountOfDependents, MedicalPlanName, MemberID, ContractEffectiveDate, InitialContribution, imageURLs) {
    let body = '';

    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">Hello ' + Name.substring(0,Name.indexOf(' ')) + '!</span></p><br>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">Our records indicate your initial contribution was declined for your WeShare Healthcare by UHSM membership. Please provide us with the updated payment information using the attached form to avoid any interruption to your membership. Please complete the form and return via email to <a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</a></span></p><br>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">Please see below for important details of your WeShare membership:</span></p>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">&nbsp;</span></p>';
    body += '<table style="border-collapse:collapse;border:none;">';
    body += '    <tbody>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: 1pt solid windowtext;border-left: 1pt solid windowtext;border-bottom: none;border-right: none;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;"><br></td>';
    body += '            <td style="width: 292.5pt;border-top: 1pt solid windowtext;border-left: none;border-bottom: none;border-right: 1pt solid windowtext;background: rgb(237, 125, 49);padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:white;">Membership Information</span></strong></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Primary Name</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + PrimaryName + '</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;"><strong><span style="line-height:107%;color:black;">Benefit Level</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;"><span style="line-height:107%;">' + CountOfDependents + '</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Company</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>UHSM</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Program Name</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + MedicalPlanName + '</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">ID Number</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span>' + MemberID + '</span></strong></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: none;border-right: none;border-bottom: none;border-image: initial;border-left: 1pt solid windowtext;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><strong><span style="color:black;">Effective Date</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: none;border-bottom: none;border-left: none;border-image: initial;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span>' + ContractEffectiveDate + '</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-left: 1pt solid windowtext;border-image: initial;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><strong><span style="color:black;">Initial Contribution (first month)</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: 1pt solid windowtext;border-right: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-image: initial;border-left: none;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;"><span style="line-height:107%;">$' + InitialContribution + '</span></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '        <tr>';
    body += '            <td style="width: 157.25pt;border-top: none;border-left: 1pt solid windowtext;border-bottom: 1pt solid windowtext;border-right: none;background: white;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><strong><span style="color:black;">Initial Contribution Status**</span></strong></p>';
    body += '            </td>';
    body += '            <td style="width: 292.5pt;border-top: none;border-left: none;border-bottom: 1pt solid windowtext;border-right: 1pt solid windowtext;padding: 0in 5.4pt;vertical-align: top;">';
    body += '                <p style="margin-right:0in;margin-left:0in;margin-top:0in;line-height:107%;margin:0in;"><strong><span style="color:#E74C3C;">DECLINED</span></strong></p>';
    body += '            </td>';
    body += '        </tr>';
    body += '    </tbody>';
    body += '</table>';
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">&nbsp;</span></p>';   
    body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in;"><span style="color:black;">We are committed to helping you make the most of your membership, and our goal is to provide each Members the care they deserve. For any questions, contact us at:  <strong>1-800-900-8476  or <a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</a></strong></span></p>';

    body += Signature(imageURLs)


    return body;
}