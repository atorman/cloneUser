@isTest
public class GeneralClonerTest {
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

            communityNickname = 'gctest' + timestamp;
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
        return tempUser('GeneralCloner', 'Test',
                        'generalclonertest@example.net');
    }

    @isTest static void testIdConstructor() {
        User u = tempUser();

        insert u;
        try {
            GeneralCloner gc = new GeneralCloner(u.Id);

            System.assert(true);
        } finally {
            u.IsActive = false;
            update u;
        }
    }

    @isTest static void testIdConstructorInvalidId() {
        try {
            Id uId = '005000000000000';
            GeneralCloner gc = new GeneralCloner(uId);
        } catch (NoDataFoundException e) {
            System.assert(true);
        }
    }

    @isTest static void testUsernameConstructor() {
        User u = tempUser();

        insert u;
        try {
            GeneralCloner gc = new GeneralCloner(u.UserName);

            System.assert(true);
        } finally {
            u.IsActive = false;
            update u;
        }
    }

    @isTest static void testUsernameConstructorInvalidUsername() {
        try {
            GeneralCloner gc = new GeneralCloner('foo');
        } catch (NoDataFoundException e) {
            System.assert(true);
        }
    }

    @isTest static void testCloneAndInsert() {
        User u = tempUser();

        insert u;
        try {
            GeneralCloner gc = new GeneralCloner(u.Id);
            Id cId = gc.cloneAndInsert('John', 'Smith',
                                       'jsmith@example.net');
            User clone = [select Id from User where Id = :cId];

            System.assert(true);
            clone.IsActive = false;
            update clone;
        } finally {
            u.IsActive = false;
            update u;
        }
    }
}