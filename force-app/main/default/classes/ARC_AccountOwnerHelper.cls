public inherited sharing class ARC_AccountOwnerHelper {
    public static ARC_CompanyDetailsController.AccountManagerData getAccountManager(Id accountId) {
        ARC_CompanyDetailsController.AccountManagerData managerData = new ARC_CompanyDetailsController.AccountManagerData();

        if (accountId == null) {
            return managerData;
        }

        List<Account> accounts = [
            SELECT Id, ARC_AccountManager__r.Name, ARC_AccountManager__r.Email, ARC_AccountManager__r.Phone
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (accounts.isEmpty() || accounts[0].ARC_AccountManager__r == null) {
            return managerData;
        }

        managerData.Name = accounts[0].ARC_AccountManager__r.Name;
        managerData.Email = accounts[0].ARC_AccountManager__r.Email;
        managerData.Phone = accounts[0].ARC_AccountManager__r.Phone;
        return managerData;
    }
}