import { Signature } from "./Signature";

//Ages Up PTS mail
export function Template36(FirstName,LastName,ContractEffectiveDate, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8.0pt;line-height:15px;"><span>Hello ' + FirstName + ',</span></p>';
    body += '<p>Thank you for being a valued member of the WeShare Community!</p><br>';
    body += '<p>We want to share an update about a program change that has gone into effect since your initial enrollment on <strong>'+ContractEffectiveDate+'</strong>.</p><br><p>As members on your program move into a new age bracket, your monthly sharing amount will change because of your loved one’s age change.</p><br>';
    body += '<p>While there is no immediate change to your existing membership, we want to make you aware of this program change as it could impact your future monthly contribution amount.</p><br>';
    body += '<p>If someone on your program reaches this new age bracket within the first year of your program, this monthly sharing amount change will not go into effect until January 1, 2024. </p><br><p>If someone on your program reaches this new age bracket after the first year of your program, you will receive a 60, 30, and 14-day notice in advance of any changes to your monthly contribution amount. This change in your monthly contribution amount will go into effect the first monthly payment that occurs after the birthday of the individual on your plan who is aging up.</p><br>';
    body += '<p><p>Our Member Services team is available and happy to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at 1-800-900-8476 or send an email to <a href="mailto:Members@weshare.org">Members@weshare.org</a>.</p></p><br>';

    body += Signature(imageURLs)

    return body;
}