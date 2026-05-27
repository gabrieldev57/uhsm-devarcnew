import { LightningElement, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import pubsub from 'vlocity_ins/pubsub';

export default class CustomPlanSelector extends OmniscriptBaseMixin(LightningElement) {
    @api omniJsonData;
    @api fieldLabel = 'Select a program';

    @track options = [];
    @track selectedOptionValue;

    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        const coverageToken = params.get('c__CoverageToken');
        if (coverageToken) {
            this._autoSelectToken = coverageToken;
        }
        this.buildOptionsFromJson();
    }

    renderedCallback() {
        pubsub.register('omniscript_step', { data: this.handleOmniAction.bind(this) });
    }

    handleOmniAction(data) {
        this.omniJsonData = data;
        this.buildOptionsFromJson();
    }

    computeFlags(planName) {
        const n = (planName || '').toLowerCase();
        const isWeShare = n.includes('weshare') || n.includes('we share');
        const isLegacyOrSenior = n.includes('legacy') || n.includes('senior');

        return {
            isWeShareLegacy: isWeShare && isLegacyOrSenior,
            isWeShareStandard: isWeShare && !isLegacyOrSenior
        };
    }

        computeWeSharePlans(planName) {
        const s = (planName || '').toLowerCase().trim();

        if (s.includes('legacy') || s.includes('senior')) return '$500.00';
        if (s.includes('12k')) return '$12,000/$24,000';
        if (s.includes('10k')) return '$10,000/$20,000';
        if (s.includes('9k')) return '$9,000/$18,000';
        if (s.includes('6k')) return '$6,000/$12,000';
        if (s.includes('5k')) return '$5,000/$10,000';
        if (s.includes('3k')) return '$3,000/$6,000';
        if (s.includes('1k')) return '$1,000/$2,000';

        return null;
    }


    getJsonData() {
        return this.omniJsonData || this.omniJsonData?.omniJsonData || {};
    }

    getOptionsNode() {
        const d = this.getJsonData();
        return d?.options || d?.result?.options || {};
    }

    getDisplayProgramOptions() {
        const optionsNode = this.getOptionsNode();
        return optionsNode?.displayProgramOptions || optionsNode?.programSelectOptions || [];
    }

    getProgramOptions() {
        const optionsNode = this.getOptionsNode();
        return optionsNode?.programOptions || [];
    }

    getMembersByProgramToken() {
        const optionsNode = this.getOptionsNode();
        return optionsNode?.membersByProgramToken || {};
    }

    getProgramByToken() {
        const optionsNode = this.getOptionsNode();
        return optionsNode?.programByToken || {};
    }

    getDefaultSelectionValue() {
        const d = this.getJsonData();
        const optionsNode = this.getOptionsNode();

        return (
            d?.selectedOptionValue ||
            d?.selectedSelectionToken ||
            d?.result?.selectionTokenUsed ||
            optionsNode?.defaultSelectionToken ||
            optionsNode?.defaultProgramToken ||
            null
        );
    }

    resolveSelection(selectedValue) {
        const programByToken = this.getProgramByToken();
        const membersByProgramToken = this.getMembersByProgramToken();

        if (!selectedValue) {
            return null;
        }

        const parts = String(selectedValue).split('|');

        let programToken;
        let selectionToken = null;
        let program = null;
        let member = null;

        if (parts.length === 2) {
            programToken = selectedValue;
            program = programByToken[programToken] || null;

            const members = membersByProgramToken[programToken] || [];
            member = members.length ? members[0] : null;
            selectionToken = member?.value || null;
        } else if (parts.length === 3) {
            programToken = `${parts[0]}|${parts[1]}`;
            selectionToken = selectedValue;
            program = programByToken[programToken] || null;

            const members = membersByProgramToken[programToken] || [];
            member = members.find((m) => String(m?.value) === String(selectionToken)) || null;
        } else {
            return null;
        }

        if (!program) {
            return null;
        }

        return {
            selectedValue,
            programToken,
            selectionToken,
            program,
            member
        };
    }

    applySelection(selectedValue) {
    const resolved = this.resolveSelection(selectedValue);
    if (!resolved) {
        return;
    }

    const { programToken, selectionToken, program, member } = resolved;

    const planName = program?.planName || program?.label || null;
    const productId = program?.productId || null;
    const flags = this.computeFlags(planName);

    let weSharePlans = this.computeWeSharePlans(planName);
    if (!weSharePlans && flags.isWeShareLegacy) {
        weSharePlans = '$500.00';
    }

    const currentPdfData = this.getJsonData()?.pdfData ? this.getJsonData().pdfData : {};

    this.omniApplyCallResp({
        selectedOptionValue: selectedValue,
        selectedProgramToken: programToken || null,
        selectedSelectionToken: selectionToken || null,
        selectedProductId: productId || null,
        selectedPlanName: planName || null,
        weSharePlans,
        pdfData: {
            ...currentPdfData,
            planName: planName || currentPdfData.planName,
            productId: productId || currentPdfData.productId,
            coverageId: program?.coverageId || currentPdfData.coverageId,
            insurancePolicyId: program?.policyId || currentPdfData.insurancePolicyId,
            weSharePlans,
            ...(member
                ? {
                      coverageParticipantId: member.coverageParticipantId || currentPdfData.coverageParticipantId,
                      policyParticipantId: member.policyParticipantId || currentPdfData.policyParticipantId,
                      memberName: program?.primaryMemberName || currentPdfData.memberName,
                      memberId: program?.primaryMemberId || currentPdfData.memberId,
                      role: member.role || currentPdfData.role,
                      primaryContactEmail: member.contactEmail || currentPdfData.primaryContactEmail,
                      memberStartDate: member.startDate || currentPdfData.memberStartDate,
                      memberEndDate: member.endDate || currentPdfData.memberEndDate,
                      relationshipToInsured: member.relationshipToInsured || currentPdfData.relationshipToInsured
                  }
                : {})
        },
        ...flags
    });
}


    _tryAutoSelect() {
        if (!this._autoSelectToken || !this.options.length) return;

        const match = this.options.find(
            (opt) => String(opt.value).startsWith(this._autoSelectToken)
        );

        if (match) {
            this.selectedOptionValue = match.value;
            this.applySelection(this.selectedOptionValue);
            this._autoSelectToken = null;
            this.omniNextStep();
        }
    }

    buildOptionsFromJson() {
        const displayOptions = this.getDisplayProgramOptions() || [];

        const membersByProgramToken = this.getMembersByProgramToken();
        const programByToken = this.getProgramByToken();

        this.options = displayOptions.map((opt) => {
            const token = String(opt.value);
            const parts = token.split('|');
            // Selection tokens have 3 parts (program|plan|member); program token is first 2
            const programToken = parts.length >= 2 ? `${parts[0]}|${parts[1]}` : token;
            const program = programByToken[programToken] || null;
            // Use ARC_CoveragePrimaryMember__r.Name as the display name in the combobox
            const memberName = program?.primaryMemberName || null;
            const label = memberName ? `${opt.label} - ${memberName}` : opt.label;
            return { label, value: token, productId: opt.productId || null };
        });

        const defaultValue = this.getDefaultSelectionValue();

        if (!this.selectedOptionValue && defaultValue) {
            const exists = this.options.some((o) => String(o.value) === String(defaultValue));

            if (exists) {
                this.selectedOptionValue = String(defaultValue);
                this.applySelection(this.selectedOptionValue);
                return;
            }
        }

        if (!this.selectedOptionValue && this.options.length) {
            this.selectedOptionValue = this.options[0].value;
            this.applySelection(this.selectedOptionValue);
        }

        // Attempt auto-select from URL param after options are ready
        if (this._autoSelectToken) {
            this._tryAutoSelect();
        }
    }

    handleChange(event) {
        this.selectedOptionValue = event.detail.value;
        this.applySelection(this.selectedOptionValue);
    }
}