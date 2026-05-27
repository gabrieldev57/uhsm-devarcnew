public with sharing class ARC_Templates {

	// SUBJECT: WeShare Healthcare by UHSM: Monthly Contribution Received
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 4. MUST BE UPDATED HERE AS WELL.
	public static String Template4(String firstName,String plans,Decimal chargeAmount, List<Document> icons) {
		String body = '';
		body += '<table style="border: none;">';
		body += '    <tbody>';
		body += '        <tr>';
		body += '            <td style="padding:.75pt .75pt .75pt .75pt;">';
		body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hi ' + firstName + ',</span></p>';
		body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thank you for this month&apos;s contribution of&nbsp;</span><strong><span>$' + chargeAmount + '</span></strong><span>&nbsp;towards member sharing. Please allow up to 1-5 additional business days for the contribution to be withdrawn from your account.</span></p><br>';
		body += '                <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thanks for being a Member of the WeShare community!</span></p><br>';

		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);
		return body;
	}

	//SUBJECT: WeShare Healthcare by UHSM: Monthly Contribution Notice
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 5. MUST BE UPDATED HERE AS WELL. 
	public static String Template5(String firstName, String monthlyContributionDate, String monthlyContributionAmount, List<Document> icons){
		String body = '';
		body += '  <p dir="ltr"><span>';
		body += '  Hi '+ firstName +',';
		body += '  </span></p><br>';
		body += '  <p dir="ltr">';
		body += '      Your next monthly contribution is due in 3 days. No action is required as it will be automatically withdrawn from the account we have on file.';
		body += '  </p><br>';
		body += '  <p dir="ltr">';
		body += '      <strong>Monthly Contribution Due Date:</strong> ' + monthlyContributionDate;
		body += '      <br>';
		body += '      <strong>Monthly Contribution Amount:</strong> $' + monthlyContributionAmount;
		body += '  </p><br>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Thanks for being a Member of the WeShare community!</span></p><br>';
	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);

		return body;
	}

	// SUBJECT: UHSM: Initial Payment Decline
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 6. MUST BE UPDATED HERE AS WELL. 
	public static String Template6(String firstName, String memberId, String plans, String paymentMethod, String paymentLast4, List<Document> icons){

		String body = '';

		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + firstName + ',</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records currently indicate that your <strong>initial contribution was declined</strong> for your WeShare membership.</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><strong><span style="color:red;">If your contribution is not received, your membership will be cancelled.</span></strong></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Please provide us with the updated payment information using the attached form to ensure your Sharing Program is activated. Once you complete the form, you can return it via email to </span><a href="mailto:Members@weshare.org"><span style="color:#0563C1;">Members@weshare.org</span></a><span> or by fax to Attn: Billing at 1-888-858-3315.</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>You may also call us directly at 1-800-900-8476 with any questions.</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thanks for being a valuable member of the WeShare community!</span></p>';

		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);	
	
		return body;
	}

    // SUBJECT: Payment CC Expiration – WeShare
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 9. MUST BE UPDATED HERE AS WELL.
    public static String Template9(String FirstName,String Last4Digits, List<Document> icons, Boolean hasMetalPlan, Boolean eftFormSent) {
        String body = '';

		if(eftFormSent == true){
			body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ', </p>';
			body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate that your credit card on file' + (hasMetalPlan == false ? ' ending in ' + Last4Digits : '') + ' is expiring soon.</span></p>';
			body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Please fill out the DocuSign form sent separately, '+(hasMetalPlan == false ? 'or update your payment information in the member portal at <a href="https://app.weshare.org"">https://app.weshare.org"</a>' : 'respond to this email, or call us at <strong>1-800-900-8476</strong> as soon as possible to provide your updated expiration date')+'.</span></p>';
			body += (hasMetalPlan == false ? '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>You may also contact us directly at <a href="mailto:Members@weshare.org">Members@weshare.org</a> or call us <strong>1-800-900-8476</strong> to provide your updated expiration date.</span></p>' : '' );
		} else {
			body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ', </p>';
			body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate that your credit card on file' + (hasMetalPlan == false ? ' ending in ' + Last4Digits : '') + ' is expiring soon. </span></p>';

			if (hasMetalPlan == false) {
				body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Please update your payment information in the member portal at <a href="https://app.weshare.org">https://app.weshare.org"/a>.</span></p>';
				body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>You may also contact us directly at <a href="mailto:Members@weshare.org">Members@weshare.org</a> or call us <strong>1-800-900-8476</strong> to provide your updated expiration date.</span></p>';
			} else {
				body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Please respond to the email or call us at <strong>1-800-900-8476</strong> as soon as possible to provide your updated expiration date.</span></p>';
			}
		}

                
        Map<String, String> generatedURLs = generateImageURLs(icons);
        body += Signature(generatedURLs);   
        return body;
    }

	// Cancellation Confirmation Notice
	public static String Template11(String firstName, String medical, String contractInactiveDate, String enrollmentEndDate, List<Document> icons) {
		String body = '';

		body += '<table style="border: none;">';
		body += '	<tbody>';
		body += '		<tr>';
		body += '			<td style="padding:.75pt 7.5pt .75pt 7.5pt;">';
	 
     
        body += '               <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">Dear ' + firstName + ',</span></p>';
        body += '               <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">We&apos;re sorry to see you go! This is your email confirmation that your WeShare Healthcare by UHSM membership: <strong>' + medical + ' </strong>'+( String.isNotBlank(contractInactiveDate) ? 'has been cancelled as of '+ contractInactiveDate : 'will be cancelled as of '+ enrollmentEndDate)+ +'.</span></p><br>';
        body += '               <p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span style="color:black;">You will not incur any further charges. Please contact us if you have received this notification in error.</span></p>';
        body += '               <p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span style="color:black;">If you have any additional questions please do not hesitate to contact us at&nbsp;</span><a href="mailto:Members@weshare.org"><span style="color:blue;">Members@weshare.org</span></a><span style="color:black;">&nbsp;</span><span style="color:black;">or at 1-800-900-8476.</span></p>';

		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);	
		return body;
	}

    // SUBJECT: Age 65 Notice
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 13. MUST BE UPDATED HERE AS WELL.
	public static String Template13(String recipientName, String firstName ,String fullName, String birthDate, List<Document> icons){
		String body = '';
        String you_approach_your = 'you approach your';
        String Capital_Your = 'Your';
        String your = 'your';
        String you = 'you';
        String you_are = 'you are';
        if (recipientName != firstName){
            you_approach_your = firstName+' approaches their';
            Capital_Your = firstName+'\'s';
            your = 'their';
            you = 'they';
            you_are = firstName + ' is';
        }
		body += '<p style="margin-bottom:8pt;line-height:normal;">Hi ' + recipientName + ',</p>';
		body += '<p style="margin-bottom:8pt;line-height:normal;">You\'ve got an exciting milestone coming up! As you approach your 65th birthday, we\'re here to guide you into the next phase with confidence and care.</p>';
		body += '<p style="margin-bottom:8pt;line-height:normal;">Your current WeShare membership will end on ' + birthDate + ' when you become eligible for Medicare. To continue your journey with us, you\'ll need to enroll in the WeShare Senior program using your Medicare ID.</p>';

        body += '<p style="margin-bottom:8pt;line-height:normal;"><b>What\'s coming next:</b></br>';
        body += 'Our team will be reaching out by phone in the coming days to walk you through the transition process and introduce you to the WeShare Senior Program. Legacy is designed for Members 65+ enrolled in Medicare who want continued faith-based support for their health needs along with resources for the mind, body, and spirit.</p>';

     	body += '<p style="margin-bottom:8pt;line-height:normal;">You don\'t have to take action today, but we invite you to begin exploring: </p>';
        body += '<ul style="margin-left:20px;margin-bottom:8pt;">';
		body += '    <li><a href="https://www.weshare.org/WeShare-Legacy-Program-Brochure" target="_blank">WeShare Senior program brochure</a></li>';
		body += '    <li><a href="https://www.weshare.org/weshare-medicare-checklist" target="_blank">Your medicare enrollment checklist</a></li>';
        body += '</ul>';
        
        body += '<p style="margin-bottom:8pt;line-height:normal;"><b>Have dependents on your account?</b></br>';
		body += 'If you are the Primary Sharing Member for your household and have dependents on your account, their sharing membership will stay the same. Only the Member transitioning into the WeShare Senior Program will move to a separate membership.</p>';		
        
		body += '<p style="margin-bottom:8pt;line-height:normal;"><b>Let\'s do this together</b></br>';
		body += 'We\'re committed to making this transition simple and personal. If you have any immediate questions or would like to schedule your call sooner, reach out to our team at <a href="mailto:Members@weshare.org">Members@weshare.org</a> or call 800-900-8476.</p>';
        
        body += '<p style="margin-bottom:8pt;line-height:normal;">We\'re honored to walk with you into this next season!</p>';
        
        // body += '<p style="margin-bottom:8pt;line-height:normal;">Blessings,</p>';
        
        // body += '<p style="margin-bottom:8pt;line-height:normal;">The WeShare team</p>';
      
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);		
		return body;
	}

	// SUBJECT: Age 26 Notice
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 14. MUST BE UPDATED HERE AS WELL.
	public static String Template14(String recipientName, String firstName, String fullName, List<Document> icons){
		String body = '';
	
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Hi ' + recipientName + ',</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thank you for trusting WeShare with your family&apos;s health and wellness needs!</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate '+fullName+' will soon exceed your Sharing Program\'s age limits (age 26).</span></p>';	
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>We need to adjust your current Sharing Program to reflect this change and discuss individual enrollment options for '+firstName+'. <b>Please note that these changes must be implemented before '+firstName+'\'s eligibility expires to avoid any gaps in sharing and/or re-enrollment fees.</b></span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Removal of any dependent(s) may apply changes to your current membership program, so please contact Member Services by phone at (800) 900-8476 or respond to this email as soon as possible.</span></p>';
		body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Thanks for being a valuable Member of the WeShare community and we look forward to serving you in the future.</span></p>';	

		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);
		return body;
	}

	// SUBJECT: Payment Decline – Recurring Metal
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 21. MUST BE UPDATED HERE AS WELL.
	public static String Template21(String firstName, List<Document> icons){
		String body = '';

		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%:"><span><br>Dear ' + firstName + ',</span></p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Our records currently indicate that your current month\'s contribution was declined for your WeShare membership.</p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:"><Strong>If your contribution is not received, your membership will be cancelled, effective on the date of your last sharing contribution.</Strong></p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Please fill out the DocuSign form sent separately, or reply to this email or call us <Strong>1-800-900-8476</Strong> to provide your updated payment method.</p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">A charge can be declined for a variety of reasons. For more information on why the charge was declined, please contact your bank or the bank that issued your card.</p>';


	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);	
		return body;
	}
	
	// SUBEJCT: AgesUp 60 days Out 
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 45. MUST BE UPDATED HERE AS WELL.
	public static String Template39(String firstName,String AgeOffName,String AgeOffbirthdate, String CurrentMonthlyContribution,String NewMonthlyContribution,Integer NextTransactionMonth, String ProgramName, List<Document> icons){
		String body = '';
		body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p>';
		body += '<p>You\'ve got a celebration coming up! With your '+ AgeOffName +' birthday on '+ AgeOffbirthdate +', your membership is moving into a new age bracket. This means there\'s a change coming to your '+ ProgramName +' Monthly Contribution Amount. <span style="font-weight:bold;">There is no action required on your part.</span></p>';
		body += '<p>Your current Monthly Contribution Amount of $'+currentmonthlycontribution +' will change to $'+ newMonthlycontribution+' and will be reflected in your membership beginning on '+getMonthName(Integer.valueOf(NextTransactionMonth))+'.</p>';
		body += '<p>Our Member Services team is happy to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>. </p>';
		body += '<p>Thank you,</p>';
	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);        
		return body;
	}

	// SUBJECT: AgesUp 30 days Out
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 46. MUST BE UPDATED HERE AS WELL.
	public static String Template40(String firstName,String AgeOffName,String AgeOffbirthdate,String nextTransactionDateformat,List<Document> icons){
		String body = '';
		body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p>';
		body += '<p>This is a reminder that your Monthly Contribution Amount will be changing soon. With your upcoming '+ AgeOffName +' birthday on '+ AgeOffbirthdate +', your membership is moving into a new age bracket and your new Monthly Contribution Amount is effective on '+nextTransactionDateformat+'</p>';
		body += '<p>Our Member Services team is available to assist with any questions you may have, any time Monday through Friday from 7am – 5pm PT. Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>. </p>';
		body += '<p>Thank you,</p>';
	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);	
		return body;
	}

	//SUBJECT: AgesUp 14 days Out
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 47. MUST BE UPDATED HERE AS WELL.
	public static String Template41(String firstName,String AgeOffName,String AgeOffbirthdate,String CurrentMonthlyContribution,String NewMonthlyContribution,Integer NextTransactionMonth, List<Document> icons){
		String body = '';
		body += '<p style="margin-bottom:8.0pt;line-height:15px;">Hey ' + FirstName + ',</p>';
		body += '<p>One last reminder about an upcoming change to your Monthly Contribution Amount! Your current Monthly Contribution Amount of $'+ currentmonthlycontribution +' will change to $'+ newMonthlycontribution +' and will be reflected in your membership beginning on '+ getMonthName(Integer.valueOf(NextTransactionMonth)) +'.';
		body += '<p>Have questions about this change? Call us at (800) 900-UHSM (8476) or send an email to <a href="mailto:memberservices@uhsm.org">memberservices@uhsm.org</a>. </p>';
	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);
		return body;
	}

	//SUBJECT: Healthy Discount 90 days out
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 48. MUST BE UPDATED HERE AS WELL.
	public static String Template42(String firstName,String ExpirationDate, List<Document> icons){
		String body = '';
		body += '<p style="margin-bottom:8.0pt;line-height:15px;">Dear ' + firstName + ',</p>';
		body += '<p>Let’s keep the savings going!</p><br>';
		body += '<p><p>Your Healthy Discount is approaching its annual expiration date,  '+ ExpirationDate +'. To be considered for this monthly contribution discount for the next year. </p> </p><br>';
		body += '<p><span style="font-weight:bold;">Please follow the steps below:</span></p><br>';
		body += '<ol style="list-style:decimal;margin-left:13px;">';
		body += '    <li style="margin-left:43px;"><span>Login to the <a href="https://app.weshare.org"" target="_blank">member portal</a>, navigate to the Healthy Discount tab, and download and complete the lab requisition form.</span></a></li>';
		body += '    <li style="margin-left:43px;"><span>Visit a <a href="https://www.labcorp.com/" target="_blank">Labcorp of America</a> location: Take your lab order to Labcorp of America to have your routine blood test performed; pay your $10 Consultation Fee. <b>Do not</b> use your WeShare ID for billing. Please ensure that LabCorp bills to the account listed on the lab order.</span></li>';
		body += '    <li style="margin-left:43px;"><span>Sit back, relax, and allow 7-10 business days for review of your labs. Once reviewed, we’ll send you an e-mail detailing the outcome and what to expect next.</span></li>';
		body += '</ol>';
		body += '<p> </p><br>';
		body += '<p><span style="text-decoration: underline;">Failure to obtain your annual lab work prior to its expiration date will result in your healthy discount being removed.</span></p><br>';
		body += '<p><p>Our Member Services team would be delighted to assist you if you need help navigating the discount renewal process!  You can call us at (800) 900-8476 or send an email to <a href="memberservices@uhsm.org">memberservices@uhsm.org</a>. </p> </p><br>';
		body += '<p>We value your commitment to your health and well-being and appreciate your continued trust with WeShare Healthcare by UHSM. We look forward to serving you for another year with our exclusive Healthy Discount</p><br>';

		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);
        
		return body;
	}

	//SUBJECT: Healthy Discount 30 days out
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 49. MUST BE UPDATED HERE AS WELL.
	public static String Template43(String firstName,String ExpirationDate, List<Document> icons){
		String body = '';
		body += '<p style="margin-bottom:8.0pt;line-height:15px;">Dear ' + firstName + ',</p>';
		body += '<p>We hope you are doing well! Following up from up prior communication, your Healthy Discount is approaching its annual expiration date, '+ ExpirationDate +'. We kindly request that you promptly initiate the renewal process to be considered for this monthly contribution discount for the next year.</p><br>';
		body += '<p><span style="font-weight:bold;">Please follow the steps below:</span></p><br>';
		body += '<ol style="list-style:decimal;margin-left:13px;">';
		body += '    <li style="margin-left:43px;"><span>Login to the <a href="https://app.weshare.org" target="_blank">member portal</a>, navigate to the Healthy Discount tab, and download and complete the lab requisition form.</span></a></li>';
		body += '    <li style="margin-left:43px;"><span>Visit a <a href="https://www.labcorp.com/" target="_blank">Labcorp of America</a> location: Take your lab order to Labcorp of America to have your routine blood test performed; pay your $10 Consultation Fee. <b>Do not</b> use your WeShare ID for billing. Please ensure that LabCorp bills to the account listed on the lab order.</span></li>';
		body += '    <li style="margin-left:43px;"><span>Sit back, relax, and allow 7-10 business days for review of your labs. Once reviewed, we’ll send you an e-mail detailing the outcome and what to expect next.</span></li>';
		body += '</ol>';
		body += '<p> </p><br>';
		body += '<p><span style="text-decoration: underline;">Failure to obtain your annual lab work prior to its expiration date will result in your healthy discount being removed.</span></p><br>';
		body += '<p><p>Our Member Services team would be delighted to assist you if you need help navigating the discount renewal process!  You can call us at (800) 900-8476 or send an email to <a href="memberservices@uhsm.org">memberservices@uhsm.org</a>. </p> </p><br>';
		body += '<p>We value your commitment to your health and well-being and appreciate your continued trust with WeShare Healthcare by UHSM. We look forward to serving you for another year with our exclusive Healthy Discount.</p><br>';
	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);
        
		return body;
	}

	//SUBJECT: Payment Decline – Recurring WeShare
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 59. MUST BE UPDATED HERE AS WELL.
	public static String Template59(String firstName, List<Document> icons){
		String body = '';

		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%:"><span><br>Dear ' + FirstName + ',</span></p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Our records currently indicate that your current month\'s contribution was declined for your WeShare membership.</p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:"><Strong>If your contribution is not received, your membership will be cancelled, effective on the date of your last sharing contribution.</Strong></p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">Please update your payment information in the member portal at <a href="https://app.weshare.org/auth/log-in"><Strong>https://app.weshare.org/auth/log-in</Strong></a> or via the DocuSign sent to your email separately.</p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">You may also reply to this email or call us <Strong>1-800-900-8476</Strong> to provide your updated payment method.</p>';
		body += '<p style="margin-right:0in;margin-left:0in;margin-top:0in;margin-bottom:8.0pt;line-height:107%;margin:0in:">A charge can be declined for a variety of reasons. For more information on why the charge was declined, please contact your bank or the bank that issued your card.</p>';


	
		Map<String, String> generatedURLs = generateImageURLs(icons);
		body += Signature(generatedURLs);	

		return body;
	}

	//SUBJECT: Payment CC Expiration – Metal
	// NOTE: This template exist in ARC_EmailsTemplateOnDemand LWC Template 60. MUST BE UPDATED HERE AS WELL.
    public static String Template60(String FirstName, List<Document> icons) {
        String body = '';

        body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Dear ' + FirstName + ', </p>';
        body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:8.0pt;margin-left:0in;line-height:normal;"><span>Our records indicate that your credit card on file is expiring soon.</span></p>';
        body += '<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;line-height:normal;"><span>Please respond to the email or call us at <strong>1-800-900-8476</strong> as soon as possible to provide your updated expiration date.</span></p>';
                
        Map<String, String> generatedURLs = generateImageURLs(icons);
        body += Signature(generatedURLs);   
        return body;
    }
	
	public static String getMonthName(Integer monthNumber) {
		List<String> monthNames = new List<String>{
			'January', 'February', 'March', 'April', 'May', 'June',
			'July', 'August', 'September', 'October', 'November', 'December'
		};
		if (monthNumber >= 1 && monthNumber <= 12) {
			return monthNames[monthNumber - 1];
		}
		return '';
	}

	public static String Signature(Map<String,String> imageURLs) {
		String signature = '';
		signature += '<br>';
		signature += '<table style="border: none; border-collapse: collapse; margin-right: calc(57%); ">';
		signature += '	<tbody>';
		signature += '		<tr>';
		signature += '			<td rowspan="5" style="width: 26.1868%;border-right: 2px solid #cdd0d4; Padding: 10px;">';
		signature += '				    <img src='+imageURLs.get('WeShareUHSM')+' style="width: 300px;"/>';
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
		signature += '				<a href="https://www.facebook.com/wesharebyuhsm "><img src='+imageURLs.get('FacebookIcon')+' ></a> <a href="https://www.twitter.com/weshare_by_uhsm "><img src='+imageURLs.get('TwitterIcon')+'></a> <a href="https://www.instagram.com/weshare_by_uhsm"><img src='+imageURLs.get('InstagramIcon')+'></a> <a href="https://www.linkedin.com/company/wesharebyuhsm"><img src='+imageURLs.get('LinkedinIcon')+' ></a>';
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

	public static Map<String, String> generateImageURLs(List<Document> icons) {
        String orgURL = 'https://' + String.valueOf(System.URL.getSalesforceBaseURL().getHost());
        Map<String, String> imageURLs = new Map<String, String>();

        for (Document i : icons) {
            if (i.Name == 'EFTForm') {
                imageURLs.put(i.Name, orgURL + '/servlet/servlet.FileDownload?file=' + i.Id);
            } else {
                imageURLs.put(i.Name, orgURL + '/servlet/servlet.ImageServer?id=' + i.Id + '&oid=' + UserInfo.getOrganizationId());
            }
        }

        return imageURLs;
    }
}