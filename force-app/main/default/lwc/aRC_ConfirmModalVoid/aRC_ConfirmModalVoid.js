import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class aRC_ConfirmModalVoid extends LightningModal {

    @api caseNumber;

    handleCancel() {
        this.close('cancel');
    }

    handleConfirm() {
        this.close('confirm');
    }
}