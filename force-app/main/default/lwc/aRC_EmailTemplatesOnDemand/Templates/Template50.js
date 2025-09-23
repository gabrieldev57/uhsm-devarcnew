//Healthy Discount Renewal Approved
import { Signature } from "./Signature";

export function Template50(FirstName, imageURLs) {
    return `
        <p style="margin-bottom:8.0pt;line-height:15px;">Hello ${FirstName},</p>
        <p>Congratulations! You have been approved for another year of the Healthy Discount program with WeShare.</p>
        <p>We are so happy to have you in our community and we look forward to helping you save money as you pursue a healthier lifestyle!</span></p><br>
        <p><span style="font-weight:bold;">What does this mean?</span></p>
        <p>You are eligible for up to 20% off your monthly contribution through the approval of your bloodwork and health care profile. 
        This discount will apply for the next 12-months and will take effect during your next billing cycle.</p><br>
        <p><span style="font-weight:bold;">How to renew your program?</span></p>
        <p>Members need to complete bloodwork annually, within 90 days of each 13-month period, from the Healthy Discount program activation date. Members will receive a communication around renewal to complete their annual bloodwork to reapply for the discount.</p><br>
        <p>Please refer to the terms and conditions for more information on the Healthy Discount program and how to reapply.</p><br>
        ${Signature(imageURLs)}
    `
}