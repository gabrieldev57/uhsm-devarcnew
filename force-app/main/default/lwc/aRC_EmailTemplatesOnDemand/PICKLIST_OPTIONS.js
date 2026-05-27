const PICKLIST_OPTIONS = [{
    label: 'Welcome Packet/ID Request Notice - Hard Copy',
    subject: 'WeShare Healthcare by UHSM: Confirmation Notice',
    value: '1',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Payment Redraft Confirmation Email',
    subject: 'WeShare Healthcare by UHSM: Update Confirmation',
    value: '3',
    params: ["First Name", "Last 4 Digits", "Next Transaction Date", "imageURLs"]
},
{
    label: 'Monthly Contribution Received',
    subject: 'WeShare Healthcare by UHSM: Monthly Contribution Received',
    value: '4',
    params: ["First Name", "Monthly Contribution", "imageURLs"]
},
{
    label: 'Monthly Contribution Notice',
    subject: 'WeShare Healthcare by UHSM: Monthly Contribution Notice',
    value: '5',
    params: ["First Name", "Charge Date", "Monthly Contribution", "imageURLs"]
},
{
    label: 'Initial Payment Decline - (Automated)',
    subject: 'Please Act Now To Keep Your UHSM Membership',
    value: '6',
    params: ["First Name", "Member ID", "Medical Plan", "Payment Method", "Last 4 Digits", "imageURLs"]
},
{
    label: 'Demographic Update Notice',
    subject: 'WeShare Healthcare by UHSM: Update Confirmation',
    value: '7',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Payment Method Update Confirmation',
    subject: 'WeShare Healthcare by UHSM: Update Confirmation',
    value: '8',
    params: ["First Name", "Last 4 Digits", "Next Transaction Date", "imageURLs"]
},
{
    label: 'Payment CC Expiration – WeShare',
    subject: 'Important Notice Regarding Your WeShare Membership',
    value: '9',
    params: ["First Name", "Last 4 Digits", "imageURLs"]
},
{
    label: 'Withdraw Confirmation – No First Month Contribution',
    subject: 'Important Notice Regarding Your WeShare Membership',
    value: '10',
    params: ["First Name", "imageURLs"]
},
//{
//    label: 'Cancellation Confirmation Notice (Automated)',
//    subject:'IMPORTANT NOTICE REGARDING YOUR MEMBERSHIP STATUS',
//    value: '11',
//    params: ["First Name", "Medical Plan", "Contract Inactive Date", "imageURLs", "ContractStatus"]
//},
{
    label: 'Age 65 Notice',
    subject: 'Age 65 Notice',
    value: '13',
    params: ["Primary Name", "First Name", "Full Name", "Projected Paid Through Date", "imageURLs"]
},
{
    label: 'Age 26 Notice',
    subject: 'Age 26 Dependent Aging Out',
    value: '14',
    params: ["Primary Name", "First Name", "Full Name", "imageURLs"]
},
{
    label: 'Medical Review Follow Up APPROVED /Reprocessed',
    subject: 'WeShare Healthcare by UHSM: Medical Review Follow Up',
    value: '15',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Message Received',
    subject: 'WeShare Healthcare by UHSM Follow Up',
    value: '16',
    params: ["imageURLs"]
},
{
    label: 'Closing Cancelation Request MEMBERS ONLY',
    subject: 'WeShare Healthcare by UHSM: Important Notice Regarding Your Membership',
    value: '17',
    params: ["First Name", "imageURLs"]
},
//{
//    label: 'Approval Resend',
//    subject: 'Welcome to WeShare Healthcare by UHSM!',
//    value: '18',
//    params: ["First Name", "Primary Name", "Medical Benefit Level", "Medical Plan", "Member ID", "Contract Effective Date", "Old Monthly Contribution", "Initial Contribution", "Charge Date", "imageURLs"]
//},
//{
//    label: 'Access Program Approval',
//    subject: 'WeShare Healthcare by UHSM: Access Program Approval',
//    value: '19',
//    params: ["First Name", "Primary Name", "Medical Benefit Level", "Medical Plan", "Member ID", "Contract Effective Date", "Monthly Contribution", "Initial Contribution", "Charge Date", "imageURLs", "imageURLs"]
//},
{
    label: 'Payment Decline – Recurring Metal',
    subject: 'Please Act Now To Keep Your WeShare Membership',
    value: '21',
    params: ["First Name", "imageURLs"]
},
//{
//    label: '(A.I.D.D): Approval Email',
//    subject: 'WeShare Healthcare by UHSM(A.I.D.D): Approval Email',
//    value: '22',
//    params: ["Full Name", "Primary Name", "AIDD Benefit Level", "AIDD Plan", "Member ID", "Contract Effective Date", "AIDD Plan Price", "Charge Date", "imageURLs"]
//},
//{
//    label: '(A.I.D.D) Cancellation Confirmation',
//    subject: 'IMPORTANT NOTICE REGARDING YOUR MEMBERSHIP STATUS',
//    value: '23',
//    params: ["First Name", "AIDD Plan", "Contract Inactive Date", "imageURLs", "ContractStatus"]
//},
//{
//    label: '(A.I.D.D): Cancelled due to no contribution',
//    subject: 'IMPORTANT NOTICE REGARDING YOUR WESHARE HEALTHCARE BY UHSM MEMBERSHIP',
//    value: '24',
//    params: ["First Name", "AIDD Plan", "Contract Inactive Date", "imageURLs", "ContractStatus"]
//},
//{
//    label: '(A.I.D.D) Initial Payment Decline',
//    subject: 'PLEASE ACT NOW TO KEEP YOUR WESHARE HEALTHCARE BY UHSM MEMBERSHIP',
//    value: '25',
//    params: ["First Name", "AIDD Plan", "Next Transaction Date", "imageURLs"]
//},
//{
//    label: '(SMART): Approval Email',
//    subject: 'WeShare Healthcare by UHSM(SMART): Approval Email',
//    value: '26',
//    params: ["Full Name", "Primary Name", "SMART Benefit Level", "SMART Plan", "Member ID", "Contract Effective Date", "SMART Plan Price", "Charge Date", "imageURLs"]
//},
//{
//    label: '(SMART): Cancellation Confirmation',
//    subject: 'IMPORTANT NOTICE REGARDING YOUR MEMBERSHIP STATUS',
//    value: '28',
//    params: ["First Name", "SMART Plan", "imageURLs", "Contract Inactive Date", "ContractStatus"]
//},
//{
//    label: '(SMART): Cancelled due to no contribution',
//    subject: 'IMPORTANT NOTICE REGARDING YOUR WESHARE HEALTHCARE BY UHSM MEMBERSHIP',
//    value: '29',
//    params: ["First Name", "SMART Plan", "imageURLs", "Contract Inactive Date", "ContractStatus"]
//},
//{
//    label: '(SMART) Initial Payment Decline',
//    subject: 'PLEASE ACT NOW TO KEEP YOUR WESHARE HEALTHCARE BY UHSM MEMBERSHIP',
//    value: '30',
//    params: ["First Name", "SMART Plan", "Next Transaction Date", "imageURLs"]
//},
//{
//    label: 'Approved (Payment decline) MP Network',
//    subject: 'WeShare Healthcare by UHSM: Approved Membership - Contribution Declined',
//    value: '31',
//    params: ["Full Name", "Primary Name", "Medical Benefit Level", "Medical Plan", "Member ID", "Contract Effective Date", "Initial Contribution", "imageURLs"]
//},
{
    label: 'Missed Callback , Left VOICEMAIL Email',
    subject: 'WeShare Healthcare by UHSM: Follow UP',
    value: '32',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Missed Callback , could not leave a voicemail email',
    subject: 'WeShare Healthcare by UHSM: Follow Up',
    value: '33',
    params: ["First Name", "imageURLs"]
},
//{
//    label: 'Age Out:',
//    subject: 'WeShare Healthcare by UHSM: Follow Up',
//    value: '36',
//    params: ["First Name", "Last Name", "Contract Effective Date", "imageURLs"]
//},
{
    label: 'Onboarding Attempt follow up',
    subject: 'WeShare Healthcare by UHSM: Follow Up',
    value: '37',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Onboarding Final Attempt',
    subject: 'WeShare Healthcare by UHSM: Follow Up',
    value: '38',
    params: ["First Name", "imageURLs"]

},
{
    label: 'Cancelation Request Final Reach out',
    subject: 'WeShare Healthcare by UHSM: Membership',
    value: '42',
    params: ["First Name", "imageURLs"]

},
{
    label: 'Initial + Follow Up Cancelation Request Follow Up',
    subject: 'Don’t Say Goodbye just yet, Let us Help!',
    value: '43',
    params: ["First Name", "imageURLs"]

},
{
    label: 'Cancel Request Pending follow up working on solution update',
    subject: 'Recent Request Important Update',
    value: '44',
    params: ["First Name", "imageURLs"]

},
{
    label: 'Age Up 60 Days Out',
    subject: 'Notice of upcoming change to your WeShare monthly sharing amount',
    value: '45',
    params: ["First Name", "AgeUp", "Oldest Member Birthdate", "Program Name", "Monthly Contribution", "Ages Up Draft Date", "Next Contribution In Sixty Days", "imageURLs"]

},
{
    label: 'Age Up 30 Days Out',
    subject: 'Reminder of upcoming change to your WeShare monthly sharing amount',
    value: '46',
    params: ["First Name", "AgeUp", "Oldest Member Birthdate", "Ages Up Effective Date", "imageURLs"]

},
{
    label: 'Age Up 14 Days Out',
    subject: 'Reminder of upcoming change to your WeShare monthly sharing amount',
    value: '47',
    params: ["First Name", "Oldest Member Name", "Oldest Member Birthdate", "Monthly Contribution", "Ages Up Draft Date", "Next Contribution In Sixty Days", "imageURLs"]

},
//{
//    label: 'Application Denial',
//    subject: 'Regarding your Application to UHSM WeShare Program',
//    value: '53',
//    params: ["First Name", "imageURLs"]
//
//},
{
    label: 'Member Google Review',
    subject: 'Share Your Experience',
    value: '54',
    params: ["First Name", "imageURLs"]

},
//{
//    label: 'Approved Email: Healthy Discount Approved',
//    subject: 'WeShare Healthcare by UHSM: Follow Up',
//    value: '34',
//    params: ["First Name", "imageURLs"]
//},
{
    label: 'Healthy Discount Renewal Approved',
    subject: 'WeShare Healthcare by UHSM: Follow Up',
    value: '50',
    params: ["First Name", "imageURLs"]

},
//{
//    label: 'Healthy Discount Denial',
//    subject: 'Healthy Discount Lab Results Criteria',
//    value: '51',
//    params: ["First Name", "imageURLs"]
//
//},
{
    label: 'Healthy Discount 90 Days Out',
    subject: 'ACTION REQUIRED: RENEW YOUR HEALTHY DISCOUNT BEFORE EXPIRATION',
    value: '48',
    params: ["First Name", "HD Expiration Date", "imageURLs"]

},
{
    label: 'Healthy Discount 60 Days Out',
    subject: 'REMINDER ACTION REQUIRED: RENEW YOUR HEALTHY DISCOUNT BEFORE EXPIRATION',
    value: '52',
    params: ["First Name", "HD Expiration Date", "imageURLs"]

},
{
    label: 'Healthy Discount 30 Days Out',
    subject: 'REMINDER ACTION REQUIRED: RENEW YOUR HEALTHY DISCOUNT BEFORE EXPIRATION',
    value: '49',
    params: ["First Name", "HD Expiration Date", "imageURLs"]

},
{
    label: 'Healthy Discount Application',
    subject: 'Healthy Discount Application',
    value: '55',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Missing Lab for Spouse',
    subject: 'Action Required: Healthy Discount Status',
    value: '56',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Non-Locate Requisition Form',
    subject: 'Requisition Form for Application',
    value: '57',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Withdraw Confirmation – No App Fee',
    subject: 'Important Notice Regarding Your WeShare Membership',
    value: '58',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Payment Decline – Recurring WeShare',
    subject: 'Please Act Now To Keep Your WeShare Membership',
    value: '59',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Payment CC Expiration – Metal',
    subject: 'Important Notice Regarding Your UHSM Membership',
    value: '60',
    params: ["First Name", "imageURLs"]
},
{
    label: 'Withdraw Confirmation – Generic',
    subject: 'Important Notice Regarding Your WeShare Application',
    value: '61',
    params: ["First Name", "imageURLs"]
}
]

export default PICKLIST_OPTIONS;