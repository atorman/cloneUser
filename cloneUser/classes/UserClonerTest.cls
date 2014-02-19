@isTest
public class UserClonerTest {
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

            communityNickname = 'uctest' + timestamp;
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
        return tempUser('UserCloner', 'Test',
                        'userclonertest@example.net');
    }

    @isTest static void testIdConstructor() {
        User u = tempUser();

        insert u;
        try {
            UserCloner uc = new UserCloner(u.Id);

            System.assert(true);
        } finally {
            u.IsActive = false;
            update u;
        }
    }

    @isTest static void testIdConstructorInvalidId() {
        try {
            Id uId = '005000000000000';
            UserCloner uc = new UserCloner(uId);
        } catch (NoDataFoundException e) {
            System.assert(true);
        }
    }

    @isTest static void testUsernameConstructor() {
        User u = tempUser();

        insert u;
        try {
            UserCloner uc = new UserCloner(u.UserName);

            System.assert(true);
        } finally {
            u.IsActive = false;
            update u;
        }
    }

    @isTest static void testUsernameConstructorInvalidUsername() {
        try {
            UserCloner uc = new UserCloner('foo');
        } catch (NoDataFoundException e) {
            System.assert(true);
        }
    }

    @isTest static void testClone() {
        User u = tempUser();

        insert u;
        try {
            UserCloner uc = new UserCloner(u.Id);
            User clone = (User)uc.clone('John', 'Smith',
                                        'jsmith@example.net');

            System.assert(true);
        } finally {
            u.IsActive = false;
            update u;
        }
    }

    @isTest static void testCloneUsernameCollision() {
        User u1 = tempUser('John', 'Smith', 'jsmith@example.net',
                           null, 'jsmith@example.net', null);
        User u2 = tempUser('John', 'Smith', 'jsmith@example.net',
                           null, 'john.smith@example.net', null);

        insert u1;
        insert u2;
        try {
            UserCloner uc = new UserCloner(u1.Id);
            User clone = (User)uc.clone('John', 'Smith',
                                        'jsmith@example.net');

            System.assertNotEquals(u1.Username, clone.Username);
            System.assertNotEquals(u2.Username, clone.Username);
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
        }
    }

    @isTest static void testCloneUsernameCollisionNullFirstName() {
        User u1 = tempUser(null, 'Smith', 'jsmith@example.net',
                           null, 'jsmith@example.net', null);
        User u2 = tempUser(null, 'Smith', 'jsmith@example.net',
                           null, 'john.smith@example.net', null);

        insert u1;
        insert u2;
        try {
            UserCloner uc = new UserCloner(u1.Id);
            User clone = (User)uc.clone(null, 'Smith',
                                        'jsmith@example.net');

            System.assertNotEquals(u1.Username, clone.Username);
            System.assertNotEquals(u2.Username, clone.Username);
        } finally {
            u1.IsActive = false;
            u2.IsActive = false;
            update u1;
            update u2;
        }
    }

    @isTest static void testCloneAndInsert() {
        User u = tempUser();

        insert u;
        try {
            UserCloner uc = new UserCloner(u.Id);
            Id cId = uc.cloneAndInsert('John', 'Smith',
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