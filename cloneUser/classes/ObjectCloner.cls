/**
 * Clone functionality for an sObject.
 *
 * @author idalton
 * @modified atorman
 * @modified jbrock
 * @since August 2013
 */
public class ObjectCloner {
    private Map<String, Schema.SObjectType> objectMap;
    private String objectName;
    private Map<String, Schema.SObjectField> fieldMap;
    private Set<String> fieldNames;
    private Set<String> userIdFieldNames;

    public ObjectCloner(String objectName) {
        this.objectMap = Schema.getGlobalDescribe();
        this.objectName = String.escapeSingleQuotes(objectName);
        if (!this.objectMap.containsKey(this.objectName)) {
            System.debug('Skipping non-existent object ' + this.objectName);
            return;
        }
        this.fieldMap =
            this.objectMap.get(this.objectName).getDescribe().fields.getMap();
        this.fieldNames = this.fieldMap.keySet();
        this.userIdFieldNames = getUserIdFieldNames();
    }

    /**
     * Return a set of names of fields on the object that reference the User
     * object.
     *
     * @return a set of names of fields.
     */
    private Set<String> getUserIdFieldNames() {
        Schema.SObjectType userType = this.objectMap.get('User');
        Set<String> userIdFieldNames = new Set<String>{};

        for (String fieldName : this.fieldNames) {
            Schema.DescribeFieldResult field =
                this.fieldMap.get(fieldName).getDescribe();

            if (field.getType() == Schema.DisplayType.Reference) {
                Set<Schema.SObjectType> refs =
                    new Set<Schema.SObjectType>(field.getReferenceTo());

                if (refs.contains(userType)) {
                    userIdFieldNames.add(fieldName);
                }
            }
        }
        return userIdFieldNames;
    }

    /**
     * Return a list of the records to clone.
     *
     * @param clause      SOQL clause to filter the objects by.
     * @param origUserId  original User Id that the record contains a reference
     *                    to.
     * @return a list of the records to clone.
     */
    private SObject[] getOriginalRecords(Id origUserId, String[] clauses) {
        if (null == clauses) {
            clauses = new String[]{};
        }
        String fieldList = String.join(new List<String>(this.fieldNames), ', ');
        String[] userIdClauses = new String[]{};
        String[] whereList = new String[]{};

        for (String userIdFieldName : this.userIdFieldNames) {
            String userIdClause = userIdFieldName + ' = :origUserId';

            userIdClauses.add(userIdClause);
        }
        if (!userIdClauses.isEmpty()) {
            String userIdExpr = '(' + String.join(userIdClauses, ' or ') + ')';

            whereList.add(userIdExpr);
        }
        if (!clauses.isEmpty()) {
            System.debug(clauses);
            String clausesExpr = '(' + String.join(clauses, ' and ') + ')';

            whereList.add(clausesExpr);
        }
        String whereExpr = String.join(whereList, ' and ');
        String query = ('select ' + fieldList + ' from ' + this.objectName
                        + ' where ' + whereExpr);
        System.debug('Running query: ' + query);
        return Database.query(query);
    }

    /**
     * Create and return a list of cloned records of the given object.
     *
     * @param origUserId    original User Id that the record contains a
     *                      reference to.
     * @param clonedUserId  Id of the User clone to update the fields to.
     * @return a list of record clones.
     */
    public SObject[] clone(Id origUserId, Id clonedUserId, String[] clauses) {
        SObject[] clonedRecords = new SObject[]{};

        if (!this.objectMap.containsKey(this.objectName)) {
            System.debug('Skipping non-existent object ' + this.objectName);
            return clonedRecords;
        }
        for (SObject record : getOriginalRecords(origUserId, clauses)) {
            SObject clonedRecord = record.clone();

            for (String userIdFieldName : this.userIdFieldNames) {
                if (clonedRecord.get(userIdFieldName) == origUserId) {
                    clonedRecord.put(userIdFieldName, clonedUserId);
                }
            }
            clonedRecords.add(clonedRecord);
        }
        return clonedRecords;
    }

    public SObject[] clone(Id origUserId, Id clonedUserId, String clause) {
        String[] clauses =
            (null == clause) ? new String[]{} : new String[]{clause};

        return clone(origUserId, clonedUserId, clauses);
    }
}