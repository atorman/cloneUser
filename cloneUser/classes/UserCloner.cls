/**
 * Clone functionality for just a User record and not it's related records.
 * use GeneralCloner class to clone both a User record and it's related records.
 *
 * @author idalton
 * @modified atorman
 * @February 2014
 */
public class UserCloner {
    private Map<String, Schema.SObjectType> gd;
    private String objectName = 'User';
    private Map<String, Schema.SObjectField> fieldMap;
    private Id userId;

    private UserCloner(Id userId, Boolean isVerifiedId) {
        this.gd = Schema.getGlobalDescribe();
        this.fieldMap = this.gd.get(this.objectName
                                    ).getDescribe().fields.getMap();
        if (isVerifiedId) {
            this.userId = userId;
        } else {
            try {
                this.userId = [select Id from User where Id = :userId].Id;
            } catch (QueryException e) {
                throw new NoDataFoundException();
            }
        }
    }

    public UserCloner(Id userId) {
        this(userId, false);
    }

    public UserCloner(String username) {
        try {
            this([select Id from User where Username = :username].Id, true);
        } catch (QueryException e) {
            throw new NoDataFoundException();
        }
    }

    /**
     * Converts all of the characters in each of the Strings in the set to
     * lowercase using the rules of the default locale.
     */
    private Set<String> toLowerCase(Set<String> strs) {
        Set<String> lcs = new Set<String>();
        for (String str : strs) {
            lcs.add(str.toLowerCase());
        }
        return lcs;
    }

    /**
     * Return a set of Strings that are in the first set but not the second.
     */
    private Set<String> setDifference(Set<String> a, Set<String> b) {
        Set<String> c = a.clone();
        c.removeAll(b);
        return c;
    }

    /**
     * Return a String of up to maxLength characters that is the concatenation
     * of as many characters of prefix as will fit and all of suffix.
     */
    private static String truncatedName(String prefix, String suffix,
                                        Integer maxLength) {
        suffix = (null == suffix) ? '' : suffix;
        return (prefix.substring(0, Math.min(prefix.length(),
                                             maxLength - suffix.length()))
                + suffix);
    }

    /**
     * Return an alias made of the first character of the first name (if
     * non-null) concatenated with the last name, truncated to the standard
     * length (5 characters).
     */
    private static String deriveAliasFromName(String firstName,
                                              String lastName) {
        String alias;
        if (String.isEmpty(firstName)) {
            alias = lastName;
        } else {
            alias = firstName.substring(0, 1) + lastName;
        }
        // default alias is up to 5 characters long
        return truncatedName(alias, null, 5);
    }

    /**
     * Return whether any records of the object have the specified field
     * equal to the specified value.
     */
    private static boolean anyRecordHasFieldValue(String fieldName,
                                                  String value) {
        return !Database.query('select Id from User where '
                               + String.escapeSingleQuotes(fieldName)
                               + ' = :value').isEmpty();
    }

    /** These private methods assume the email address is valid.  This is
     * a legitimate move because that constraint is checked internally
     * when the User's email is set.
     */
    
    private static String localPart(String email) {
        return email.subString(0, email.indexOf('@'));
    }

    private static String domainName(String email) {
        return email.subString(email.indexOf('@') + 1);
    }

    /**
     * Return a name with a random number based on the timestamp included that
     * is guaranteed to be unique across all users.
     */
    private static String timestampedName(String fieldName, String local,
                                          String domain, Integer maxLength) {
        String name;

        do {
            String timestamp = String.valueOf(System.currentTimeMillis()
                                              + Math.random() * 10000);
            String suffix = ((null == domain)
                             ? timestamp
                             : timestamp + '@' + domain);

            name = truncatedName(local, suffix, maxLength);
        } while (anyRecordHasFieldValue('Username', name));
        return name;
    }

    /**
     * Return a unique username derived from an email address, first
     * name, and last name.
     *
     * @param email      the email address of the user.
     * @param firstName  the first name of the user.
     * @param lastName   the last name of the user.
     * @return a unique username.
     */
    private String deriveUsername(String email, String firstName,
                                  String lastName) {
        if (!anyRecordHasFieldValue('Username', email)) {
            return email;
        }

        Integer maxLength = 80;
        String local = localPart(email);
        String domain = domainName(email);

        if (!String.isEmpty(lastName)) {
            String prefix;
            String username;

            if (String.isEmpty(firstName)) {
                prefix = lastName;
            } else {
                prefix = firstName + '.' + lastName;
            }
            username = truncatedName(prefix, '@' + domain, maxLength);
            if (!anyRecordHasFieldValue('Username', username)) {
                return username;
            }
        }
        return timestampedName('Username', local, domain, maxLength);
    }

    /**
     * Return a CommunityNickname guaranteed to be unique across all users.
     */
    private static String deriveCommunityNickNameFromUsername(String username) {

        Integer maxLength = 40;
        return timestampedName('CommunityNickname', localPart(username), null,
                               maxLength);
    }

    /**
     * Return the original User with only the fields selected that we wish to
     * clone.
     */
    private User getOriginalRecord() {
        Set<String> fieldBlacklist = new Set<String>{
            'AboutMe',
            'AccountId',
            'Alias',
            'CommunityNickname',
            'ContactId',
            'CreatedById',
            'CreatedDate',
            'CurrentStatus',
            'DelegatedApproverId',
            'Email',
            'EmployeeNumber',
            'Extension',
            'Fax',
            'FederationIdentifier',
            'FirstName',
            'FullPhotoUrl',
            'Id',
            'LastLoginDate',
            'LastModifiedById',
            'LastModifiedDate',
            'LastName',
            'LastPasswordChangeDate',
            'LastReferencedDate',
            'LastViewedDate',
            'MobilePhone',
            'Name',
            'OfflinePdaTrialExpirationDate',
            'OfflineTrialExpirationDate',
            'Phone',
            'SenderEmail',
            'SenderName',
            'Signature',
            'SmallPhotoUrl',
            'StayInTouchNote',
            'StayInTouchSignature',
            'StayInTouchSubject',
            'SystemModstamp',
            'UserType',
            'Username',
            'WirelessEmail'
        };
        Set<String> fieldsToCopy =
            setDifference(this.fieldMap.keySet(), toLowerCase(fieldBlacklist));
        String fieldList = String.join(new List<String>(fieldsToCopy), ', ');
        
        // query string can't use :this.userId; use :userId instead
        String userId = this.userId;
        String query = 'select ' + fieldList + ' from User where Id = :userId';
        return Database.query(query);
    }

    /**
     * Create and return a User cloned from the original User, with the name,
     * email, alias, username, and community nickname fields set to the given
     * parameters, or, in the case of the latter three, derived if null.
     *
     * @param firstName          the first name of the new user.
     * @param lastName           the last name of the new user.
     * @param email              the email address of the new user.
     * @param alias              the alias of the new user.
     *                           Will be derived if null.
     * @param username           the username of the new user.
     *                           Will be derived if null.
     * @param communityNickname  the community nickname of the new user.
     *                           Will be derived if null.
     * @return the new User.
     */
    public SObject clone(String firstName, String lastName, String email,
                         String alias, String username,
                         String communityNickname) {
        User orig = (User)getOriginalRecord();
        User uo = orig.clone();

        uo.FirstName = firstName;
        uo.LastName = lastName;
        uo.Email = email;
        uo.Alias = ((null != alias)
                    ? alias
                    : deriveAliasFromName(firstName, lastName));
        username = ((null != username)
                    ? username
                    : deriveUsername(email, firstName, lastName));
        uo.Username = username;
        uo.CommunityNickname =
            ((null != communityNickname)
             ? communityNickname
             : deriveCommunityNickNameFromUsername(username));
        return (SObject)uo;
    }

    /**
     * Create and return a User cloned from the original User, with the name and
     * email fields set to the given parameters, and the alias, username, and
     * community nickname fields derived.
     *
     * @param firstName          the first name of the new user.
     * @param lastName           the last name of the new user.
     * @param email              the email address of the new user.
     * @return the new User.
     */
    public SObject clone(String firstName, String lastName, String email) {
        return clone(firstName, lastName, email, null, null, null);
    }

    /**
     * Clone and insert a User and return its Id.
     *
     * @param firstName          the first name of the new user.
     * @param lastName           the last name of the new user.
     * @param email              the email address of the new user.
     * @param alias              the alias of the new user.
     *                           Will be derived if null.
     * @param username           the username of the new user.
     *                           Will be derived if null.
     * @param communityNickname  the community nickname of the new user.
     *                           Will be derived if null.
     * @return the Id of the new User.
     */
    public Id cloneAndInsert(String firstName, String lastName, String email,
                             String alias, String username,
                             String communityNickname) {
        SObject uo = clone(firstName, lastName, email, alias, username,
                           communityNickname);
        insert uo;
        return uo.Id;
    }

    /**
     * Clone and insert a User and return its Id.
     *
     * @param firstName          the first name of the new user.
     * @param lastName           the last name of the new user.
     * @param email              the email address of the new user.
     * @return the Id of the new User.
     */
    public Id cloneAndInsert(String firstName, String lastName, String email) {
        return cloneAndInsert(firstName, lastName, email, null, null, null);
    }
}