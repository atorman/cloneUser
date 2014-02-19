/**
 * Clone functionality for a User record and related records.
 *
 * @author idalton
 * @modified atorman
 * @since August 2013
 */
public class GeneralCloner {
    private Id origUserId;
    private Id clonedUserId;
    
    // extension constructor
    public User usr;
    
    public GeneralCloner (ApexPages.StandardController stdController)
    {
       this.usr = (User)stdController.getRecord(); 
    }

    private GeneralCloner(Id userId, Boolean isVerifiedId) {
        if (isVerifiedId) {
            this.origUserId = userId;
        } else {
            try {
                this.origUserId = [select Id from User where Id = :userId].Id;
            } catch (QueryException e) {
                throw new NoDataFoundException();
            }
        }
    }

    public GeneralCloner(Id userId) {
        this(userId, false);
    }

    public GeneralCloner(String username) {
        try {
            this([select Id from User where UserName = :username].Id, true);
        } catch (QueryException e) {
            throw new NoDataFoundException();
        }
    }

    @future
    private static void cloneAndInsertRecords(String objectName, String clause,
                                              Id origUserId, Id clonedUserId) {
        ObjectCloner oc = new ObjectCloner(objectName);
        SObject[] clonedRecords = oc.clone(origUserId, clonedUserId, clause);
        SObject[] newClonedRecords;

       /** When a new User record is inserted, a DivisionMember record based on
        * its DefaultDivision field is automatically created and inserted. When
        * we clone all of the original User's DivisonMember records to a new
        * User, one may end up containing the same field values as the earlier,
        * automatically-created record. Ensure we exclude this equivalent
        * record before inserting.
		*/
                                                  
        if (objectName == 'DivisionMember') {
            Map<String, Schema.SObjectType> objectMap =
                Schema.getGlobalDescribe();

            if (objectMap.containsKey('DivisionMember')) {
                newClonedRecords = new SObject[]{};
                for (SObject clonedRecord : clonedRecords) {
                    Id division = (Id)clonedRecord.get('Division');
                    Id userId = (Id)clonedRecord.get('UserId');
                    SObject[] preExisting =
                        Database.query('select Division, UserId '
                                       + 'from DivisionMember '
                                       + 'where Division = :division '
                                       + 'and UserId = :userId');

                    if (preExisting.isEmpty()) {
                        newClonedRecords.add(clonedRecord);
                    }
                }
            }
        } else {
            newClonedRecords = clonedRecords;
        }
        insert newClonedRecords;
    }

    private void cloneAndInsertRecords(String objectName, String clause) {
        cloneAndInsertRecords(objectName, clause, this.origUserId,
                              this.clonedUserId);
    }

    private void cloneAndInsertRecords(String objectName) {
        cloneAndInsertRecords(objectName, null, this.origUserId,
                              this.clonedUserId);
    }

   /** Some objects are not copyable in Apex:
    *
    * - CustomSetup             object not in public API
    * - UserPackageLicense      object not in public API
    * - QueueMember             object not in public API
    * http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_dml_non_dml_objects.htm
    * - UserTeamMember          DML not supported
    * - UserAccountTeamMember   DML not supported
    * - UserTerritory           DML not supported
    *
    * Some need to be cloned in a separate transation because of
    * http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_dml_non_mix_sobjects.htm
    *
    * - User
    * - PermissionSetAssignment
    * - GroupMember
	*/
    
	/**
     * Clone and insert a User and its associated records, returning the new
     * User Id. Associated records may be created after the User Id is returned.
     *
     * @param firstName  the first name of the new user.
     * @param lastName   the last name of the new user.
     * @param email      the email address of the new user.
     * @param alias              the alias of the new user.
     *                           Will be derived if null.
     * @param username           the username of the new user.
     *                           Will be derived if null.
     * @param communityNickname  the community nickname of the new user.
     *                           Will be derived if null.
     */
    public Id cloneAndInsert(String firstName, String lastName, String email,
                             String alias, String username,
                             String communityNickname) {
        UserCloner uc = new UserCloner(this.origUserId);
        this.clonedUserId = uc.cloneAndInsert(firstName, lastName, email, alias,
                                              username, communityNickname);
        // can't assign permission sets that are associated with a profile
        cloneAndInsertRecords('PermissionSetAssignment',
                              'PermissionSet.IsOwnedByProfile = false');
        cloneAndInsertRecords('DivisionMember');
        cloneAndInsertRecords('OpportunityTeamMember');
        cloneAndInsertRecords('AccountTeamMember');
        cloneAndInsertRecords('ForecastShare');
        cloneAndInsertRecords('GroupMember');
        // FIXME: Filtering on RowCause != 'Owner' catches one record, but I
        // don't yet know why I can't clone that record. 
        cloneAndInsertRecords('UserShare',
                              'RowCause != \'Owner\'');
        return this.clonedUserId;
    }

    /**
     * Clone and insert a User and its associated records, returning the new
     * User Id. Associated records may be created after the User Id is returned.
     *
     * @param firstName  the first name of the new user.
     * @param lastName   the last name of the new user.
     * @param email      the email address of the new user.
     */
    public Id cloneAndInsert(String firstName, String lastName, String email) {
        return cloneAndInsert(firstName, lastName, email, null, null, null);
    }
}