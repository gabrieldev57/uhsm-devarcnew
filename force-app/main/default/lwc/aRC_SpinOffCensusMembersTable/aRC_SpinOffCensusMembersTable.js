import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class aRC_SpinOffCensusMembersTable extends OmniscriptBaseMixin(LightningElement) {
    @api censusMembers; // %STEP_MembersToSpinOff:membersToSpinOff%
    @track membersWithReasons = [];

    connectedCallback() {
        console.log('censusMembers ' + JSON.stringify(this.censusMembers))
        this.omniSaveState({}, 'LWC_Census', true);
        this.initializeMembersWithReasons();
    }

    initializeMembersWithReasons(){
        //Make sure censusMembers is an array
        if (!this.censusMembers) {
            console.warn('censusMembers is null or undefined');
            this.membersWithReasons = [];
            return;
        }

        const membersArray = Array.isArray(this.censusMembers) 
            ? this.censusMembers 
            : [this.censusMembers];

        this.membersWithReasons = membersArray.map((member, index) => {
            const memberCopy = {...member};

            //Set the initial TXT_reason value 
            if (member.TXT_ContractParticipantRelationship === 'Primary'){
                memberCopy.TXT_reason = 'Remove Member';
                memberCopy.NUM_assignToFamily = 1;
            } else if (member.TXT_ContractParticipantRelationship === 'Spouse' && !member.CHK_spinOffSelection){
                memberCopy.TXT_reason = 'Remove Member';
                memberCopy.NUM_assignToFamily = 1;
            } else if (member.TXT_ContractParticipantRelationship === 'Spouse' && member.CHK_spinOffSelection){
                memberCopy.TXT_reason = `${member.TXT_FirstName} ${member.TXT_LastName} Spin-Off`;
                memberCopy.NUM_assignToFamily = 2;
            } else if (member.CHK_spinOffSelection === true){
                memberCopy.TXT_reason = `${member.TXT_FirstName} ${member.TXT_LastName} Spin-Off`;
                memberCopy.NUM_assignToFamily = 0;
            } else {
                memberCopy.TXT_reason = 'Remove Member';
                memberCopy.NUM_assignToFamily = 1;
            }

            return memberCopy;
        });

        this.calculateSpinOffAssignments();

        //Update OmniScript inmediately
        this.updateOmniScriptOutput();
    }

    handleDropdownChange(event){
        const selectedLabel = event.target.options[event.target.selectedIndex].text;
        const selectedValue = event.target.value;
        const memberIndex = parseInt(event.target.dataset.memberIndex);

        const selectedMember = this.censusMembers.find(m => 
            m.TXT_ContractParticipantId === selectedValue
        );

        let assignToFamilyNumber = 1;

        if(selectedMember) {
            //Use the same order criteria as updateOmniScriptOutput
            const sortedMembers = [...this.membersWithReasons].sort((a, b) => {
                //Primary always first
                if (a.TXT_ContractParticipantRelationship === 'Primary') return -1;
                if (b.TXT_ContractParticipantRelationship === 'Primary') return 1;

                //Spouse always second
                if (a.TXT_ContractParticipantRelationship === 'Spouse') return -1;
                if (b.TXT_ContractParticipantRelationship === 'Spouse') return 1;

                // Children with Spin'Off always third
                const aShowsDropdown = a.TXT_ContractParticipantRelationship !== 'Primary' && 
                                    a.CHK_spinOffSelection !== true && 
                                    !(a.TXT_ContractParticipantRelationship === 'Spouse' && a.CHK_spinOffSelection === false);
                const bShowsDropdown = b.TXT_ContractParticipantRelationship !== 'Primary' && 
                                    b.CHK_spinOffSelection !== true && 
                                    !(b.TXT_ContractParticipantRelationship === 'Spouse' && b.CHK_spinOffSelection === false);

                if (!aShowsDropdown && bShowsDropdown) return -1;
                if (aShowsDropdown && !bShowsDropdown) return 1;

                return 0;
            });

            // Encontrar la posición en el array ORDENADO
            const sortedPosition = sortedMembers.findIndex(m =>
                m.TXT_ContractParticipantId === selectedMember.TXT_ContractParticipantId
            );
            assignToFamilyNumber = sortedPosition + 1;
        }

        // Update value of TXT_reason && NUM_assignToFamily for specific member
        this.membersWithReasons = this.membersWithReasons.map((member, index) => {
            if(index === memberIndex){
                return{
                    ...member, 
                    TXT_reason: selectedLabel,
                    NUM_assignToFamily: assignToFamilyNumber
                };
            }
            return member;
        });

        this.updateOmniScriptOutput();
    }

    updateOmniScriptOutput() {
        // Order Members to send to output Json
        const sortedMembers = [...this.membersWithReasons].sort((a, b) => {
            //Primary always first
            if (a.TXT_ContractParticipantRelationship === 'Primary') return -1;
            if (b.TXT_ContractParticipantRelationship === 'Primary') return 1;

            //Spouse always second
            if (a.TXT_ContractParticipantRelationship === 'Spouse') return -1;
            if (b.TXT_ContractParticipantRelationship === 'Spouse') return 1;

            // Children with Spin'Off always third
            const aShowsDropdown = a.TXT_ContractParticipantRelationship !== 'Primary' && 
                                  a.CHK_spinOffSelection !== true && 
                                  !(a.TXT_ContractParticipantRelationship === 'Spouse' && a.CHK_spinOffSelection === false);
            const bShowsDropdown = b.TXT_ContractParticipantRelationship !== 'Primary' && 
                                  b.CHK_spinOffSelection !== true && 
                                  !(b.TXT_ContractParticipantRelationship === 'Spouse' && b.CHK_spinOffSelection === false);

            if (!aShowsDropdown && bShowsDropdown) return -1;
            if (aShowsDropdown && !bShowsDropdown) return 1;

            //If same type keep original order
            return 0;
        });

        const outputData = sortedMembers.map(member => ({
            CHK_spinOffSelection: member.CHK_spinOffSelection,
            TXT_ContractParticipantRelationship: member.TXT_ContractParticipantRelationship,
            TXT_LastName: member.TXT_LastName,
            TXT_FirstName: member.TXT_FirstName,
            TXT_ContractParticipantId: member.TXT_ContractParticipantId,
            TXT_GroupCensusMemberId: member.TXT_GroupCensusMemberId,
            NUM_Age: member.NUM_Age,
            TXT_reason: member.TXT_reason,
            NUM_assignToFamily: member.NUM_assignToFamily
        }));

        this.omniUpdateDataJson(outputData);
    }

    //Members to display in the table
    get membersToDisplay() {
        const dataSource = this.membersWithReasons.length > 0 ? this.membersWithReasons : this.censusMembers;

        const processedMembers = dataSource.map((member, index) => {

            const primaryMember = dataSource.find(m => m.TXT_ContractParticipantRelationship === 'Primary');

            const primaryOption = primaryMember ? {
                label: `${primaryMember.TXT_FirstName} ${primaryMember.TXT_LastName}`,
                value: primaryMember.TXT_ContractParticipantId,
                isPrimary: true
            } : null;

            let otherOptions = this.selectedMembers
                .filter(selectedMember => 
                    selectedMember.TXT_ContractParticipantId !== member.TXT_ContractParticipantId && 
                    selectedMember.TXT_ContractParticipantRelationship !== 'Primary'
                )
                .filter(selectedMember => {

                    const bothAreChildren = 
                        member.TXT_ContractParticipantRelationship === 'Child' &&
                        selectedMember.TXT_ContractParticipantRelationship === 'Child';

                    const bothAreOver18 = 
                        member.NUM_Age >= 18 && 
                        selectedMember.NUM_Age >= 18;

                    if (bothAreChildren && bothAreOver18) {
                        // Don't allow pairing two children over 18
                        return false;
                    }

                    if (selectedMember.NUM_Age < 18) {
                        //If Spin-Off member is under 18, only younger members can select that Spin-Off member
                        return selectedMember.NUM_Age >= member.NUM_Age;
                    } else {
                        //If Spin-Off member is over 18, any member can select that Spin-Off member
                        return true;
                    }
                })
                .map(selectedMember => ({
                    label: `${selectedMember.TXT_FirstName} ${selectedMember.TXT_LastName}`,
                    value: selectedMember.TXT_ContractParticipantId,
                    isPrimary: false
                }));

            const filteredOptions = primaryOption ? [primaryOption, ...otherOptions] : otherOptions;
            const isSpouseNotSelected = member.TXT_ContractParticipantRelationship === 'Spouse' && member.CHK_spinOffSelection === false;
            const showDropdown = member.TXT_ContractParticipantRelationship !== 'Primary' && member.CHK_spinOffSelection !== true && !isSpouseNotSelected;
            const optionsWithSelection = filteredOptions.map(option => ({
                ...option,
                selected: member.TXT_reason === option.label
            }));

            return{
                ...member,
                originalIndex: index,
                isPrimary: member.TXT_ContractParticipantRelationship === 'Primary',
                isSpinOffSelected: member.CHK_spinOffSelection === true,
                isSpouseNotSelected: isSpouseNotSelected,
                showDropdown: showDropdown,
                rowClass: this.getRowClass(member),
                filteredOptions: optionsWithSelection,
                spinOffText: `${member.TXT_FirstName} ${member.TXT_LastName} Spin-Off`
            };
        });

        //Order to show members in table
        return processedMembers.sort((a, b) => {
            //Primary always first
            if(a.isPrimary) return -1;
            if(b.isPrimary) return 1;

            //Spouse always second
            if(a.TXT_ContractParticipantRelationship === 'Spouse') return -1;
            if(b.TXT_ContractParticipantRelationship === 'Spouse') return 1;

            //Children that don't show dropdown or Spouse not selected
            const aShowsDropdown = a.showDropdown;
            const bShowsDropdown = b.showDropdown;

            if(!aShowsDropdown && bShowsDropdown) return -1;
            if(aShowsDropdown && !bShowsDropdown) return 1;

            //If both are of the same type, keep original order
            return 0;
        });
    }

    //Grey background
    getRowClass(member) {
        if (member.TXT_ContractParticipantRelationship === 'Primary' || 
            member.CHK_spinOffSelection === true || 
            (member.TXT_ContractParticipantRelationship === 'Spouse' && member.CHK_spinOffSelection === false)) {
            return 'slds-theme_shade';
        }
        return ''; 
    }
   
    //Selected members for field Select
    get selectedMembers(){
        const dataSource = this.membersWithReasons.length > 0 ? this.membersWithReasons : this.censusMembers;
        return dataSource.filter(member => member.CHK_spinOffSelection === true);
    }

    //Primary Member
    get primaryMember(){
        const dataSource = this.membersWithReasons.length > 0 ? this.membersWithReasons : this.censusMembers;
        return dataSource.filter(member => member.TXT_ContractParticipantRelationship === 'Primary');
    }

    get dropdownOptions(){
        return this.selectedMembers.map(member => ({
            label: `${member.TXT_FirstName} ${member.TXT_LastName}`,
            value: member.TXT_ContractParticipantId
        }));
    }

    //Calculate NUM_assignToFamily criteria
    calculateSpinOffAssignments() {
        const sortedMembers = [...this.membersWithReasons].sort((a, b) => {
            //Primary always first
            if (a.TXT_ContractParticipantRelationship === 'Primary') return -1;
            if (b.TXT_ContractParticipantRelationship === 'Primary') return 1;

            //Spouse always second
            if (a.TXT_ContractParticipantRelationship === 'Spouse') return -1;
            if (b.TXT_ContractParticipantRelationship === 'Spouse') return 1;

            // Children with Spin'Off always third
            const aShowsDropdown = a.TXT_ContractParticipantRelationship !== 'Primary' && 
                                  a.CHK_spinOffSelection !== true && 
                                  !(a.TXT_ContractParticipantRelationship === 'Spouse' && a.CHK_spinOffSelection === false);
            const bShowsDropdown = b.TXT_ContractParticipantRelationship !== 'Primary' && 
                                  b.CHK_spinOffSelection !== true && 
                                  !(b.TXT_ContractParticipantRelationship === 'Spouse' && b.CHK_spinOffSelection === false);

            if (!aShowsDropdown && bShowsDropdown) return -1;
            if (aShowsDropdown && !bShowsDropdown) return 1;

            return 0;
        });

        //Update NUM_assignToFamily for members with Spin-Off
        sortedMembers.forEach((sortedMember, sortedIndex) => {
            if (sortedMember.CHK_spinOffSelection === true && 
                sortedMember.TXT_ContractParticipantRelationship !== 'Spouse') {
                
                // Encontrar el miembro en el array original y actualizar
                this.membersWithReasons = this.membersWithReasons.map(member => {
                    if (member.TXT_ContractParticipantId === sortedMember.TXT_ContractParticipantId) {
                        return {
                            ...member,
                            NUM_assignToFamily: sortedIndex + 1
                        };
                    }
                    return member;
                });
            }
        });
    }
}