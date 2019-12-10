@isTest
private without sharing class AccountTest extends BaseTest {
    @isTest
    static void testAccountInsert() {
        System.runAs(t.getTestUser()) {
            List<Account> accs = new List<Account>();
            t.start();
                for (Integer  i = 0; i < t.BULK_SIZE; ++i) {
                    accs.add(new Account(Name = 'Test'));
                }
            t.stop();
            System.assert(false, accs.size());
        }
    }

  static { BaseTest.t = new AccountTest(); 
            BaseTest.TEST_CLASS_NAME = 'AccountTest';}
  static BaseTest t { get { return BaseTest.t; } }
}
