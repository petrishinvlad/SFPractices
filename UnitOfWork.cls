public class UnitOfWork 
{
    List<Schema.SObjectType> processedTypes;
    private enum OP_TYPE {OP_INSERT, OP_UPDATE, OP_DELETE}
    Map<OP_TYPE, Map<Schema.SObjectType, List<SObject>>> data = new Map<OP_TYPE, Map<Schema.SObjectType, List<SObject>>>{
        OP_TYPE.OP_INSERT => new Map<Schema.SObjectType, List<SObject>>(),
        OP_TYPE.OP_UPDATE => new Map<Schema.SObjectType, List<SObject>>(),
        OP_TYPE.OP_DELETE => new Map<Schema.SObjectType, List<SObject>>()};

    Map<Schema.SObjectType, Relationships> relations = new Map<Schema.SObjectType, Relationships>();

    //prerequisite for stub api???
    public UnitOfWork()
    {

    }

    public UnitOfWork(List<Schema.SObjectType> typesToProcess)
    {
        //deepClone might be used
        this.processedTypes = typesToProcess.clone();
    }

    public void registerSObjectType(Schema.SObjectType objType) 
    {
        for (Map<Schema.SObjectType, List<SObject>> dataByDml : data.values())
        {
            dataByDml.put(objType, new List<SObject>());
        }
        relations.put(objType, new Relationships());
    }

    public void registerToInsert(SObject record)
    {
        registerRecord(record, OP_TYPE.OP_INSERT);
    }

    public void registerToUpdate(SObject record)
    {
        registerRecord(record, OP_TYPE.OP_UPDATE);
    }

    public void registerToDelete(SObject record)
    {
        registerRecord(record, OP_TYPE.OP_DELETE);
    }

    public void registerRelation(SObject record, Schema.SObjectField relatedToField, 
                                 SObject relatedToRecord)
    {
        Schema.SObjectType objType = record.getSObjectType();
        if (!data.get(OP_TYPE.OP_INSERT).containsKey(objType)) {
            throw new UOWUnssupportedRelationTypeException(objType.getDescribe().getName() + ' is not supported');
        }
        relations.get(objType).add(record, relatedToField, relatedToRecord);
    }

    private void registerRecord(SObject record, OP_TYPE opType)
    {
        Map<Schema.SObjectType, List<SObject>> processedRecords = data.get(OP_TYPE.OP_INSERT);
        Schema.SObjectType objType = record.getSObjectType();
        if (processedTypes.contains(objType))
        {
            List<SObject> recordsByType = processedRecords.get(objType);
            recordsByType.add(record);
        }
        else 
        {
            throw new UOWUnsupportedTypeException(objType.getDescribe().getName() + ' is not supported');
        }
    }

    public void commitWork()
    {
        Savepoint sp = Database.setSavePoint();
        try 
        {
            for (Schema.SObjectType objType : data.get(OP_TYPE.OP_INSERT).keySet())
            {
                relations.get(objType).resolve();
                insert data.get(OP_TYPE.OP_INSERT).get(objType);
            }
            for (Schema.SObjectType objType : data.get(OP_TYPE.OP_UPDATE).keySet())
            {
                update data.get(OP_TYPE.OP_UPDATE).get(objType);
            }
            for (Schema.SObjectType objType : data.get(OP_TYPE.OP_DELETE).keySet())
            {
                delete data.get(OP_TYPE.OP_DELETE).get(objType);
            }
        } 
        catch (Exception ex) 
        {
            Database.rollback(sp);
            //logger
        }
        finally
        {
            //some final logic if needed
        }
    }

    private class Relationships
	{
		private List<Relationship> relations = new List<Relationship>();

		public void resolve()
		{
			for(Relationship relationship : relations)
				relationship.record.put(relationship.relatedToField, relationship.relatedTo.Id);
		}
		
		public void add(SObject record, Schema.sObjectField relatedToField, SObject relatedTo)
		{
			Relationship relationship = new Relationship();
			relationship.record = record;
			relationship.relatedToField = relatedToField;
			relationship.relatedTo = relatedTo;
			relations.add(relationship);
		}
	}
	
	private class Relationship
	{
		public SObject record;
		public Schema.sObjectField relatedToField;
		public SObject relatedTo;
	}

    private class UOWUnsupportedTypeException extends Exception {}
    private class UOWUnssupportedRelationTypeException extends Exception {}
}