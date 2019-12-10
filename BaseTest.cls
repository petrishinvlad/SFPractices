public without sharing virtual class BaseTest 
{
    public static String TEST_CLASS_NAME;
    public static BaseTest t;
    public static TestBulkSizeSetting__mdt defaultSetting = new TestBulkSizeSetting__mdt(MaxBulkSize__c = 200, 
                                                                                            MinBulkSize__c = 1, 
                                                                                            UseMaxBulk__c = false);

    @TestVisible
    private Integer BULK_SIZE{ get {
            List<TestBulkSizeSetting__mdt> settings = [SELECT MaxBulkSize__c, MinBulkSize__c, UseMaxBulk__c 
                                                FROM TestBulkSizeSetting__mdt WHERE ClassName__c =: TEST_CLASS_NAME];
            if (settings.isEmpty()) {
                settings.add(defaultSetting);
            }
            return Integer.valueOf(settings[0].get((Boolean)settings[0].UseMaxBulk__c ? 'MaxBulkSize__c' : 'MinBulkSize__c')); 
        }
    private set;}

    public void start() {
		Test.startTest();
	}

	public void stop() {
		Test.stopTest();
	}

    public User getTestUser() {
        return new User(Id = UserInfo.getUserId());
    }
}
