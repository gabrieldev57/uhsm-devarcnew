@isTest
/**
 * This test class validates the lead phone number conversion functionality.
 * It verifies that the phone numbers are converted correctly and match the expected results.
 */
private class LeadPhoneNumberConvertTest {
    /**
     * Test method to validate the lead phone number conversion.
     * Inserts leads with different phone numbers and asserts the conversion results.
     */
    static testMethod void testInsertLeadPhone(){
        // Expected result for lead phone number conversion
        String expected_result = '+11234445566';
        
        // Insert leads with different phone numbers
        insertLead('PhoneTest1', '+11234445566', expected_result);
        insertLead('PhoneTest2', '1234445566', expected_result);
        insertLead('PhoneTest3', '123.444.5566', expected_result);
        insertLead('PhoneTest4', '(123) 444-5566', expected_result);
        insertLead('PhoneTest5', '123-444-5566', expected_result);
        insertLead('PhoneTest6', '11234445566', expected_result);
        insertLead('PhoneTestNull', '', null);
    }
    
    /**
     * Helper method to insert a lead, assert the phone number conversion,
     * and delete the lead afterward to avoid duplicate rule triggers.
     *
     * @param last_name   The last name of the lead.
     * @param test_phone  The phone number of the lead to be inserted.
     * @param assertion  The expected result of the phone number conversion.
     */
    private static void insertLead(String last_name, String test_phone, String assertion){
		// Create a lead with the specified last name and phone number
        Lead test_lead = new Lead(LastName = last_name, Phone = test_phone);
        insert test_lead;
        
        // Query the inserted lead to ensure the insert performed as expected
        test_lead = [select Phone from Lead where Id=:test_lead.id];
        
        // Assert that the lead's phone number is converted correctly
        System.AssertEquals(test_lead.Phone, assertion);
        
        // Delete the lead to avoid triggering duplicate rules
        delete test_Lead;
    } 
}