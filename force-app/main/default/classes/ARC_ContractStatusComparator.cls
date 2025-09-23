public class ARC_ContractStatusComparator implements Comparator<Contract> {

    public Integer compare(Contract contract1, Contract contract2) {
        // Get the status of both contracts
        String status1 = contract1.Status;
        String status2 = contract2.Status;
        
        // Compare based on the predefined order of statuses
        if (status1 == 'Activated' && status2 != 'Activated') {
            return -1; // 'Activated' is higher priority
        } else if (status1 != 'Activated' && status2 == 'Activated') {
            return 1; // 'Activated' is higher priority
        }

        if (status1 == 'Awaiting Activation' && status2 != 'Awaiting Activation' && status2 != 'Activated') {
            return -1; // 'Awaiting Activation' comes after 'Activated'
        } else if (status1 != 'Awaiting Activation' && status2 == 'Awaiting Activation') {
            return 1; // 'Awaiting Activation' comes after 'Activated'
        }

        if (status1 == 'Awaiting Approval' && status2 != 'Awaiting Approval' && status2 != 'Activated' && status2 != 'Awaiting Activation') {
            return -1; // 'Awaiting Approval' comes after 'Activated'
        } else if (status1 != 'Awaiting Approval' && status2 == 'Awaiting Approval') {
            return 1; // 'Awaiting Approval' comes after 'Activated'
        }

        if (status1 == 'Awaiting Signature' && status2 != 'Awaiting Signature' && status2 != 'Activated' && status2 != 'Awaiting Approval' && status2 != 'Awaiting Activation') {
            return -1; // 'Awaiting Signature' comes after 'Awaiting Activation'
        } else if (status1 != 'Awaiting Signature' && status2 == 'Awaiting Signature') {
            return 1; // 'Awaiting Signature' comes after 'Awaiting Activation'
        }

        if (status1 == 'Awaiting for First Payment' && status2 != 'Awaiting for First Payment' && status2 != 'Activated' && status2 != 'Awaiting Approval' && status2 != 'Awaiting Activation' && status2 != 'Awaiting Signature') {
            return -1; // 'Awaiting for First Payment' comes after 'Awaiting Signature'
        } else if (status1 != 'Awaiting for First Payment' && status2 == 'Awaiting for First Payment') {
            return 1; // 'Awaiting for First Payment' comes after 'Awaiting Signature'
        }

        if (status1 == 'Terminated' && status2 != 'Terminated' && status2 != 'Activated' && status2 != 'Awaiting Approval' && status2 != 'Awaiting Activation' && status2 != 'Awaiting Signature' && status2 != 'Awaiting for First Payment') {
            return -1; // 'Terminated' comes after 'Awaiting Signature'
        } else if (status1 != 'Terminated' && status2 == 'Terminated') {
            return 1; // 'Terminated' comes after 'Awaiting Signature'
        }

        if (status1 == 'Voided' && status2 != 'Voided' && status2 != 'Activated' && status2 != 'Awaiting Approval' && status2 != 'Awaiting Activation' && status2 != 'Awaiting Signature' && status2 != 'Awaiting for First Payment' && status2 != 'Terminated') {
            return -1; // 'Voided' comes after 'Awaiting Signature'
        } else if (status1 != 'Voided' && status2 == 'Voided') {
            return 1; // 'Voided' comes after 'Awaiting Signature'
        }

        if (status1 == 'Draft' && status2 != 'Draft' && status2 != 'Activated' && status2 != 'Awaiting Approval' && status2 != 'Awaiting Activation' && status2 != 'Awaiting Signature' && status2 != 'Awaiting for First Payment' && status2 != 'Terminated' && status2 != 'Voided') {
            return -1; // 'Draft' comes after 'Awaiting Signature'
        } else if (status1 != 'Draft' && status2 == 'Draft') {
            return 1; // 'Draft' comes after 'Awaiting Signature'
        }

        // If both contracts have the same status
        return 0;
    }
}