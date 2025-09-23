import { Signature } from "./Signature";

//UHSM Healthy Discount Denied Email
export function Template35(FirstName, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hello ' + FirstName + ',</p>';
    body += '<p>Thank you for applying for the WeShare Healthy Discount program.</p><p>Unfortunately, your compiled health care profile was not approved at this time.</p><br>';
    body += '<p><span style="font-weight:bold;">What does this mean?</span>.</p>';
    body += '<p><p>A representative from DocDay will be in contact with you to provide assistance through a chronic care management program. You must participate in this program to be accepted for future Healthy Discount consideration. You may re-apply for the Healthy Discount after 90-days of being an active participant in the chronic care management program. Members will be responsible for additional bloodwork or medical costs incurred.</p> </p><br>';
    body += '<p><p>Download DocDay in the Apple or Android Stores and keep track of important health metrics, appointments, and updates to be accepted for future Healthy Discount consideration.</p> </p><br>';
    body += '<p><p>Please refer to the terms and conditions for more information on the Healthy Discount program and how to reapply.</p> </p><br>';
 
    body += Signature(imageURLs)

    return body;
}