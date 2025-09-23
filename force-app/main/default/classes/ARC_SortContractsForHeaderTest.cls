@isTest
public class ARC_SortContractsForHeaderTest {
    @isTest
    static void sortMethodTerminated() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        List<Contract> listContract = ARC_TestUtility.createContracts(2);
        String mapInfo = '{"Contracts":[{"NeverActive":false,"EffectiveDate":"2022-01-01","CreatedDate":"2022-01-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Terminated","InactiveDate":"2022-06-01","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"},{"NeverActive":false,"EffectiveDate":"2022-06-01","CreatedDate":"2022-06-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Terminated","InactiveDate":"2022-12-01","contractId":"'+listContract[1].Id+'","Id":"a3q3C000001IgLhQAK"}], "Promotions": [{"Id": "aDC8K000000L11YWAS","ContractId": "'+listContract[0].Id+ '"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);
        ARC_SortContractsForHeader newClass = new ARC_SortContractsForHeader();
        newClass.invokeMethod('SortContractsForHeader',inputMap,outputMap,options);
    }
    @isTest
    static void sortMethodActive() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        List<Contract> listContract = ARC_TestUtility.createContracts(2);
        String mapInfo = '{"Contracts":[{"NeverActive":false,"EffectiveDate":"2022-01-01","CreatedDate":"2021-01-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Activated","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"},{"NeverActive":false,"EffectiveDate":"2022-01-01","CreatedDate":"2022-01-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Activated","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);
        ARC_SortContractsForHeader newClass = new ARC_SortContractsForHeader();
        newClass.invokeMethod('SortContractsForHeader',inputMap,outputMap,options);
    }
    @isTest
    static void sortMethodInactiveSignature() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        List<Contract> listContract = ARC_TestUtility.createContracts(2);
        String mapInfo = '{"Contracts":[{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Signature","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"},{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Signature","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);
        ARC_SortContractsForHeader newClass = new ARC_SortContractsForHeader();
        newClass.invokeMethod('SortContractsForHeader',inputMap,outputMap,options);
    }
    @isTest
    static void sortMethodInactiveActivation() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        List<Contract> listContract = ARC_TestUtility.createContracts(2);
        String mapInfo = '{"Contracts":[{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Activation","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"},{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Activation","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);
        ARC_SortContractsForHeader newClass = new ARC_SortContractsForHeader();
        newClass.invokeMethod('SortContractsForHeader',inputMap,outputMap,options);
    }
    @isTest
    static void sortMethodInactiveApproval() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        List<Contract> listContract = ARC_TestUtility.createContracts(2);
        String mapInfo = '{"Contracts":[{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Approval","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"},{"NeverActive":false,"EffectiveDate":"2023-01-01","CreatedDate":"2022-12-30T16:22:41.000Z","TotalPrice":554.45,"Status":"Awaiting Approval","contractId":"'+listContract[0].Id+'","Id":"a3q3C000001IgLhQAK"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);
        ARC_SortContractsForHeader newClass = new ARC_SortContractsForHeader();
        newClass.invokeMethod('SortContractsForHeader',inputMap,outputMap,options);
    }
}