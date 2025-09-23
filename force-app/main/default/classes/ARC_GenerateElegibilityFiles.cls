public with sharing class ARC_GenerateElegibilityFiles {
    
    public static void putFileInsSfLibrary(String libraryFolderName, String fileName, String fileContent) {
        if (!Test.isRunningTest()) {
            ContentVersion cv = new ContentVersion();
            cv.VersionData = Blob.valueOf(fileContent);
            cv.Title = filename;
            cv.PathOnClient = fileName;
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = :libraryFolderName LIMIT 1];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
            cdl.LinkedEntityId = ws.Id; //Magic happens here
            insert cdl;
        }
    }
}