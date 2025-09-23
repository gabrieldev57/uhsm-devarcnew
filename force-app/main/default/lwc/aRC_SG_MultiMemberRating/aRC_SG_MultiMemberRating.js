import { LightningElement, track } from 'lwc';
import sendMemberData from '@salesforce/apex/ARC_SG_MemberRatingController.sendMemberData';

export default class ArcSgMultiMemberRating extends LightningElement {
    @track members;
    @track error;
    csvData; // parsed CSV rows
    isCallDisabled = true;
    @track totalRate = 0;

    handleFileChange(event) {
        this.error = null;
        this.members = null;
        this.totalRate = 0;
        this.isCallDisabled = true;

        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                try {
                    const csv = reader.result;
                    const lines = csv.split(/\r\n|\n/);
                    const headers = lines[0].split(',');

                    const members = [];
                    for (let i = 1; i < lines.length; i++) {
                        if (!lines[i].trim()) continue;
                        const values = lines[i].split(',');
                        const obj = {};
                        headers.forEach((header, idx) => {
                            obj[header.trim()] = values[idx] ? values[idx].trim() : '';
                        });
                        members.push(obj);
                    }

                    this.csvData = members;
                    this.isCallDisabled = false;
                } catch (err) {
                    this.error = 'Error parsing CSV: ' + err.message;
                }
            };
            reader.readAsText(file);
        }
    }

    handleCallIP() {
        if (!this.csvData || this.csvData.length === 0) {
            this.error = 'No member data loaded. Please upload a CSV file first.';
            return;
        }
        this.error = null;
        this.totalRate = 0;

        const input = { members: this.csvData };

        sendMemberData({ jsonInput: JSON.stringify(input) })
            .then(result => {
                const response = JSON.parse(result);
                const ratedMembers = response?.ratedMembers || [];

                ratedMembers.forEach((rated, index) => {
                    const rateObj = rated?.memberResult?.output?.[0]?.calculationResults?.[0];
                    this.csvData[index].Rate = rateObj?.Rate ?? 0;
                });

                // Calculate total rate
                this.totalRate = this.csvData.reduce((sum, member) => {
                    const rate = parseFloat(member.Rate);
                    return sum + (isNaN(rate) ? 0 : rate);
                }, 0).toFixed(2);

                this.members = this.csvData;
            })
            .catch(error => {
                this.error = 'Error calling Apex: ' + (error.body?.message || error.message);
                this.members = null;
                this.totalRate = 0;
            });
    }
}