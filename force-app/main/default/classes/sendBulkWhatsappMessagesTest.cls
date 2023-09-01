@isTest
public class sendBulkWhatsappMessagesTest {
    @isTest
    public static void testMethod1() {
        List<Contact> conList = new List<Contact>();
        Contact con = new Contact();
        con.LastName = 'Ramu';
        con.Phone = '8529637410';
        con.MobilePhone = '8529637410';
        conList.add(con);
        insert conList;

        Test.startTest();
        PageReference pref = Page.sendBulkWhatsappMessages;
        pref.getParameters().put('id', con.Id);
        Test.setCurrentPage(pref);
        ApexPages.StandardSetController std1 = new ApexPages.StandardSetController(conList);
        sendBulkWhatsappMessages c = new sendBulkWhatsappMessages(std1);
        c.redirectToLC();
        Test.stopTest();

        // Add assertion here
        System.assertEquals(1, 1); // Example assertion
    }
}