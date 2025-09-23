import { Signature } from "./Signature";

//Age 65 Notice (ALL outside of CA)
export function Template13(FirstName, FullName, Birthdate, imageURLs) {
    let body = '';
    body += '<p style="margin-bottom:8pt;line-height:normal;">Hi ' + FirstName + ',</p>';
    body += '<p style="margin-bottom:8pt;line-height:normal;">Congratulations on an exciting milestone. As you approach your 65th birthday, we want to make sure you continue to feel cared for and supported through every stage in life.</p>';
    body += '<p style="margin-bottom:8pt;line-height:normal;">Your current WeShare membership will end on ' + Birthdate + ' as you become eligible for Medicare. To continue your journey with us, you\'ll need to enroll in the WeShare Legacy program using your Medicare ID. We\'re here to guide you into the next phase, with confidence and care.</p>';

    body += '<p style="margin-bottom:8pt;line-height:normal;"><b>What\'s coming next:</b></br>';
    body += 'Our team will be reaching out by phone in the coming days to walk you through the transition process and introduce you to the WeShare Legacy Program. Legacy is designed for members 65+ enrolled in Medicare who want continued faith-based support for their health needs along with resources for the mind, body, and spirit.</p>';

     body += '<p style="margin-bottom:8pt;line-height:normal;">You don’t have to take action today, but we invite you to begin exploring: </p>';
    body += '<ul>';
    body += '<li>  <a href="https://www.weshare.org/WeShare-Legacy-Program-Brochure" target="_blank">WeShare Legacy program brochure</a></li>';
    body += '<li>  <a href="https://www.weshare.org/weshare-medicare-checklist" target="_blank">Your medicare enrollment checklist</a></li>';
    body += '</ul></br>';
    
    body += '<p style="margin-bottom:8pt;line-height:normal;"><b>Have dependents on your account?</b></br>';
    body += 'If you are the Primary Sharing Member for your household, and have dependents on your account, their sharing membership will stay the same. Only the Member transitioning into the WeShare Legacy Program will move to a separate membership.</p>';
    
    body += '<p style="margin-bottom:8pt;line-height:normal;"><b>Let\’s do this together</b></br>';
    body += 'We\'re committed to making this transition simple and personal. If you have any immediate questions or would like to schedule your call sooner, reach out to our team at <a href="mailto:Members@weshare.org">Members@weshare.org</a> or call 800-900-8476.</p>';
    
    body += '<p style="margin-bottom:8pt;line-height:normal;">We\’re honored to walk with you into this next season.</p>';
    
    body += '<p style="margin-bottom:8pt;line-height:normal;">Blessings,</p>';
    
    body += '<p style="margin-bottom:8pt;line-height:normal;">The WeShare team</p>';

    body += Signature(imageURLs)

    return body;
}