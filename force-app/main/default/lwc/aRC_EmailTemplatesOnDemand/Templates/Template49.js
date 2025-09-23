//Healthy discount 30 days out
import { Signature } from "./Signature";

export function Template49(FirstName,ExpirationDate,imageURLs) {
    return `
    <p style="margin-bottom:8.0pt;line-height:15px;">Dear ${FirstName},</p>
    <p>We hope you are doing well! Following up from up prior communication, your Healthy Discount is approaching its annual expiration date, ${ExpirationDate}. We kindly request that you promptly initiate the renewal process to be considered for this monthly contribution discount for the next year.</p><br>
    <p><span style="font-weight:bold;">Please follow the steps below:</span></p><br>
    <ol style="list-style:decimal;margin-left:13px;">
        <li style="margin-left:43px;"><span>Login to the <a href="https://uhsm.my.site.com/members/s/login/" target="_blank">member portal</a>, navigate to the Healthy Discount tab, and download and complete the lab requisition form.</span></a></li>
        <li style="margin-left:43px;"><span>Visit a <a href="https://www.questdiagnostics.com/" target="_blank">Quest Diagnostics</a> or <a href="https://www.labcorp.com/" target="_blank">Labcorp of America</a> location: Take your lab order to Quest Diagnostic or Labcorp of America to have your routine blood test performed; pay your $10 Consultation Fee.</span></li>
        <li style="margin-left:43px;"><span>Sit back, relax, and allow 7-10 business days for review of your labs. Once reviewed, we’ll send you an e-mail detailing the outcome and what to expect next.</span></li>
    </ol>
    <p> </p><br>
    <p><span style="text-decoration: underline;">Failure to obtain your annual lab work prior to its expiration date will result in your healthy discount being removed.</span></p><br>
    <p><p>Our Member Services team would be delighted to assist you if you need help navigating the discount renewal process!  You can call us at (800) 900-8476 or send an email to <a href="memberservices@uhsm.org">memberservices@uhsm.org</a>. </p> </p><br>
    <p>We value your commitment to your health and well-being and appreciate your continued trust with WeShare Healthcare by UHSM. We look forward to serving you for another year with our exclusive Healthy Discount.</p><br>
    ${Signature(imageURLs)}`
}