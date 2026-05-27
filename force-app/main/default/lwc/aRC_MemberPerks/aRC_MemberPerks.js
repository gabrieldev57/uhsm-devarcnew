import { LightningElement, api } from 'lwc';
import CommunityHero from "@salesforce/resourceUrl/CommunityHero";


export default class ARC_MemberPerks extends LightningElement {
    @api background;

    memberPerks = [
        {
            title: 'NetworkAndProviders',
            text: '<p style="font-size:1.50rem"><b>Network & Providers</b></p>'
        },
        {
            title: 'PHCS®',
            text: '<p></p><b><a href="https://www.multiplan.com/webcenter/portal/ProviderSearch?ProviderSearchConfig=ClientSite&SiteUrlSuffix=uhsmphcsvdhp">PHCS®</a></b>,&nbsp;the largest, independent primary PPO in the nation, with over 1.2 million+ medical professionals and 5,600 hospitals. That gives members access to 95% of U.S. healthcare professionals and hospitals to get the in-person care they need throughout their wellness journey.'
        },
        {
            title: 'MinuteClinic®',
            text: '<p></p><b><a href="https://www.cvs.com/minuteclinic">MinuteClinic®</a></b> is a walk-in or virtual clinic that patients can choose as an alternative to urgent care, to get support with common illnesses like colds, flu, strep, infections (eye, ear, skin, sinus, and UTI), or medication refills.</p>',
        },
        {
            title: 'CVS Caremark™',
            text: '<p></p><b><a href="https://www.caremark.com/portal/asset/rxsavings_pharm.pdf">CVS Caremark™</a></b> is the largest retail pharmacy provider in the nation with low, pre-negotiated, member-specific rates for prescriptions at both CVS Caremark™ with 68,000 locations, and CVS MinuteClinic™ with 1,100 locations.</p>',
        },
        {
            title: 'BetterHelp',
            text: '<p></p><b><a href="https://www.betterhelp.com/">BetterHelp</a></b> was founded in 2013 to remove the traditional barriers to therapy and make mental health care more accessible to everyone. Today, it’s the world’s largest online therapy service – providing professional, affordable, and personalized therapy in a convenient online format.&nbsp;Over 30,000 licensed therapists are available via chat, phone, or video call and trained in a range of issues – from depression and anxiety to parenting challenges and relationship issues. Members are custom matched with a therapist based on their unique needs and preferences. <b>You will receive an email from BetterHelp directly to register on your effective date.</b></p>',
        },
        {
            title: 'Careington Dental',
            text: '<p><b><a href="https://uhsm.solutionssimplified.com/">Careington Dental</a></b>, an industry leader in dental care, provides you hassle-free savings to maintain your oral hygiene. You have access to one of the most recognized networks in the nation with 20-50% savings on most dental procedures, including routine oral exams, unlimited cleanings, and major work such as dentures, root canals, crowns, and more. Plus, all dentists must meet highly selective credentialing standards based on education, background, license standing, and other requirements. Simply present your discount card to your dental provider and save!</p>',
        },
        {
            title: 'Not Insurance 1',
            text: '<p style="font-size:0.785rem"><b>THIS PLAN IS NOT INSURANCE and is not intended to replace health insurance.</b> This plan does not meet the minimum creditable coverage requirements under M.G.L. c. 111M and 956 CMR 5.00. This plan is not a Qualified Health Plan under the Affordable Care Act. The range of discounts will vary depending on the type of provider and service. The plan does not pay providers directly. Plan members must pay for all services but will receive a discount from participating providers. The list of participating providers is at <a href="https://www.weshare.org/find-a-provider/">Find a Provider | Careington & WeShare</a>. A written list of participating providers is available upon request. Discount Plan Organization and administrator: Careington International Corporation, 7400 Gaylord Parkway, Frisco, TX 75034; phone 800-441-0380. This plan is not available in Vermont, Washington, and Montana.</p>',
        },
        {
            title: 'Superior Vision',
            text: '<p><b><a href="https://uhsm.solutionssimplified.com/">Superior Vision</a></b> discount programs helps you save 5-30% on eye care and wear. Discounts are offered at more than 40,000 participating providers locations on exams, eyeglasses, contact lenses, and more. You also receive 20-30% off the overall national average cost of LASIK surgery through QualSight at more than 800 locations.&nbsp;Even if you’ve got 20/20 vision, comprehensive eye exams can help detect signs of serious health conditions like glaucoma, diabetes, high blood pressure and high cholesterol.</p>',
        },
        {
            title: 'Not Insurance 2',
            text: '<p style="font-size:0.785rem"><b>THIS PLAN IS NOT INSURANCE and is not intended to replace health insurance.</b> This plan does not meet the minimum creditable coverage requirements under M.G.L. c. 111M and 956 CMR 5.00. This plan is not a Qualified Health Plan under the Affordable Care Act. The range of discounts will vary depending on the type of provider and service. The plan does not pay providers directly. Plan members must pay for all services but will receive a discount from participating providers. The list of participating providers is at <a href="https://www.weshare.org/find-a-provider/">Find a Provider | Careington & WeShare</a>. A written list of participating providers is available upon request. Discount Plan Organization and administrator: Careington International Corporation, 7400 Gaylord Parkway, Frisco, TX 75034; phone 800-441-0380. This plan is not available in Vermont, Washington, and Montana.</p>',
        },
        {
            title: 'Amwell',
            text: '<p><b><a href="https://wesharetelehealth.org/">Amwell</a></b> is virtual care that is designed to make your journey to health accessible.  Leveraging technology, Amwell gets you the care you need faster and easier than a traditional office visit, in the privacy of your own home or while on the go. With your WeShare membership you get unlimited Amwell visits at no cost to you.<b> You will receive an email from Amwell directly to register on your effective date.</b></p>',
        },
        {
            title: 'Membership Perks',
            text: '<br><p style="font-size:1.50rem"><b>Membership Perks</b></p>'
        },
        {
            title: 'Noom',
            text: '<p></p><b><a href="https://www.weshare.org/community/noom/">Noom</a></b> is bringing an end to dieting and instead help its users create life-long results. They help you create habits that change the root of specific behavior. Noom recognizes that everyone is unique, so their programs are personalized for each user’s needs and goals. Noom also provides support and services for mental wellness. Their holistic approach to health helps people achieve life-long, lasting results. <b> You will receive an email from Noom directly to register on your effective date.</b></p>',
        },
        {
            title: 'HelloFresh',
            text: '<p>WeShare, healthcare by UHSM has teamed up with <b><a href="https://www.hellofresh.com/plans?c=UHSM2024&nobx=1">HelloFresh</a></b> to provide you with America’s #1 Meal Kit at a discounted price! For your convenience, HelloFresh delivers fresh ingredients right to your doorstep to make their meals within a 6 step, 30-minute cooking model.All meals are healthy, nutritious, and most importantly delicious. To begin ordering, simply enter code: UHSM2024 at check out or utilize URL: <a href="https://www.hellofresh.com/plans?c=UHSM2024&nobx=1">Meal Kit Delivery Plans & Food Boxes | HelloFresh</a>. You’ll receive 50% off your first box and enjoy a 10% savings from there! We look forward to being healthier, together!</p>',
        },
        {
            title: 'Fitbod',
            text: '<p></p><b><a href="https://www.weshare.org/community-partners-ambassadors/fitbod/">FITBOD</a></b> is a leader in the emerging category of smart fitness guidance. Products in this space offer personalized workout & nutrition plans that are computer created, using predictive analytics and machine learning. With this tech, FITBOD learns from your workout history, understands your fitness ability, and guides you on a personalized path to results. Use code: <b>wellness</b> to get started today!</p>',
        },
        {
            title: 'rightnow media',
            text: '<p><b><a href="https://www.weshare.org/community/rightnow-media/">rightnow media</a></b> has the world’s largest customizable library of biblical video resources. Authentic videos for everyone, including, family, children, teams, and professionals to equip and inspire people beyond Sunday. <b><a href="https://app.rightnowmedia.org/en/join/UHSM/">Sign up!</a></b></p>',
        },
   
    ];

    renderedCallback() {
        this.template.querySelectorAll('.elementHoldingHTMLContent').forEach((element) => {
            element.innerHTML = this.memberPerks.find((memberPerk) => {
                return memberPerk.title === element.dataset.title;
            }).text;
        });
    }

    get headerImageURL() {
        return CommunityHero + "/" + this.background;
    }
}