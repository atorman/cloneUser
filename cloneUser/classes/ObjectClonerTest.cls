@isTest
public class ObjectClonerTest {
    static User tempUser(String firstName, String lastName,
                         String email, String alias, String userName,
                         String communityNickname) {
        if (String.isEmpty(alias)) {
            alias = (String.isEmpty((firstName))
                     ? lastName
                     : firstName.substring(0, 1) + lastName);
        }
        if (String.isEmpty(communityNickname)) {
            String timestamp = String.valueOf(System.currentTimeMillis()
                                              + Math.random() * 10000);

            communityNickname = 'octest' + timestamp;
        }
        if (String.isEmpty(userName)) {
            userName = communityNickname + '@example.net';
        }
        Profile p = [select Id from Profile where Name='Standard User'];
        User u = new User(FirstName=firstName,
                          LastName=lastName,
                          Email=email,
                          Alias=alias,
                          UserName=userName,
                          CommunityNickname=communityNickname,
                          TimeZoneSidKey='America/Los_Angeles',
                          LocaleSidKey='en_US',
                          EmailEncodingKey='ISO-8859-1',
                          ProfileId=p.Id,
                          LanguageLocaleKey='en_US');

        return u;
    }

    static User tempUser(String firstName, String lastName,
                         String email) {
        return tempUser(firstName, lastName, email, null, null, null);
    }

    static User tempUser() {
        return tempUser('ObjectCloner', 'Test',
                        'objectclonertest@example.net');
    }

    @isTest static void testConstructor() {
        ObjectCloner oc = new ObjectCloner('UserShare');
        System.assert(true);
    }

    @isTest static void testCloneClauseList() {
        User u1 = tempUser();
        User u2 = tempUser();
        PermissionSet ps = new PermissionSet(Name = 'Foo', Label = 'Foo');

        insert u1;
        insert u2;
        insert ps;

        PermissionSetAssignment psa =
            new PermissionSetAssignment(AssigneeId = u1.Id,
                                        PermissionSetId = ps.Id);

        insert psa;

        try {
            ObjectCloner oc = new ObjectCloner('PermissionSetAssignment');
            SObject[] clones =
                oc.clone(u1.Id, u2.Id,
                         new String[]{
                             'PermissionSet.IsOwnedByProfile = false'
                         });

            System.assertEquals(1, clones.size());
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
            delete psa;
            delete ps;
        }
    }

    @isTest static void testCloneClauseListNull() {
        User u1 = tempUser();
        User u2 = tempUser();
        PermissionSet ps = new PermissionSet(Name = 'Foo', Label = 'Foo');

        insert u1;
        insert u2;
        insert ps;

        PermissionSetAssignment psa =
            new PermissionSetAssignment(AssigneeId = u1.Id,
                                        PermissionSetId = ps.Id);

        insert psa;

        try {
            ObjectCloner oc = new ObjectCloner('PermissionSetAssignment');
            SObject[] clones = oc.clone(u1.Id, u2.Id, (List<String>)null);

            System.assertEquals(2, clones.size());
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
            delete psa;
            delete ps;
        }
    }

    @isTest static void testCloneClauseString() {
        User u1 = tempUser();
        User u2 = tempUser();
        PermissionSet ps = new PermissionSet(Name = 'Foo', Label = 'Foo');

        insert u1;
        insert u2;
        insert ps;

        PermissionSetAssignment psa =
            new PermissionSetAssignment(AssigneeId = u1.Id,
                                        PermissionSetId = ps.Id);

        insert psa;

        try {
            ObjectCloner oc = new ObjectCloner('PermissionSetAssignment');
            SObject[] clones =
                oc.clone(u1.Id, u2.Id,
                         'PermissionSet.IsOwnedByProfile = false');

            System.assertEquals(1, clones.size());
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
            delete psa;
            delete ps;
        }
    }

    @isTest static void testCloneClauseStringNull() {
        User u1 = tempUser();
        User u2 = tempUser();
        PermissionSet ps = new PermissionSet(Name = 'Foo', Label = 'Foo');

        insert u1;
        insert u2;
        insert ps;

        PermissionSetAssignment psa =
            new PermissionSetAssignment(AssigneeId = u1.Id,
                                        PermissionSetId = ps.Id);

        insert psa;

        try {
            ObjectCloner oc = new ObjectCloner('PermissionSetAssignment');
            SObject[] clones = oc.clone(u1.Id, u2.Id, (String)null);

            System.assertEquals(2, clones.size());
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
            delete psa;
            delete ps;
        }
    }

    @isTest static void testCloneNonExistentObject() {
        User u1 = tempUser();
        User u2 = tempUser();

        insert u1;
        insert u2;

        try {
            ObjectCloner oc = new ObjectCloner('FooBarBaz');
            SObject[] clones = oc.clone(u1.Id, u2.Id, (List<String>)null);

            System.assertEquals(0, clones.size());
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
        }
    }
}