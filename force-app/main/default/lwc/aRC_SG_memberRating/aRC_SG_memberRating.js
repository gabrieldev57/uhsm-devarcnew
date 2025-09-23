import { LightningElement } from 'lwc';
import sendMemberData from '@salesforce/apex/ARC_SG_MemberRatingController.sendMemberData';

export default class ARC_SG_memberRating extends LightningElement {
    members = [];
    result;
    isReadyToSubmit = false;

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();

            reader.onload = () => {
                const csv = reader.result;
                try {
                    this.members = this.parseCSV(csv);
                    this.isReadyToSubmit = this.members.length > 0;
                    this.result = null;
                } catch (e) {
                    console.error('CSV Parsing Error:', e);
                }
            };

            reader.readAsText(file);
        }
    }

    parseCSV(csv) {
        const lines = csv.trim().split('\n');
        const headers = lines[0].split(',').map(h => h.trim());

        const records = lines.slice(1).map(line => {
            const values = line.split(',').map(v => v.trim());
            const obj = {};
            headers.forEach((h, i) => {
                obj[h] = this.parseValue(values[i]);
            });
            return obj;
        });

        return records;
    }

    parseValue(value) {
        if (value === 'true' || value === 'false') {
            return value === 'true';
        }
        if (!isNaN(value) && value.trim() !== '') {
            return Number(value);
        }
        return value;
    }

    async handleSubmit() {
        const payload = { members: this.members };
        try {
            const response = await sendMemberData({ jsonInput: JSON.stringify(payload) });
            this.result = JSON.stringify(JSON.parse(response), null, 2);
        } catch (error) {
            this.result = 'Error: ' + (error.body?.message || JSON.stringify(error));
            console.error(error);
        }
    }
}