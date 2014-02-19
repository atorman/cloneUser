/**
 * Clone functionality for a User record.
 *
 * @author atorman@salesforce.com
 * @February 2014
 */

public class CloneUserController {
    
    // **************** CONSTRUCTORS ****************

    private Id userId;

    public CloneUserController(Id userId) {
        this.userId = userId;
    }

    public CloneUserController(String username) {
        this.userId = [select Id from User where Username = :username].Id;
    }


   // extension constructor
    public User usr;
    
    public CloneUserController (ApexPages.StandardController stdController)
    {
       this.usr = (User)stdController.getRecord(); 
    }
    
   // create a getter/setter for the Source User that is passed in when the user selects the 'clone' button
   public String srcusr  
   {
        get { return srcusr;}
        set { srcusr = value;}
    }
    
   // create a getter/setter for the first name that is passed in when the user selects the 'clone' button
   public String fname 
   {
        get { return fname;}
        set { fname = value;}
    }
       
   // create a getter/setter for the last name that is passed in when the user selects the 'clone' button
   public String lname  
   {
        get { return lname;}
        set { lname = value;}
    }
    
   // create a getter/setter for the email address that is passed in when the user selects the 'clone' button
   public String email  
   {
        get { return email;}
        set { email = value;}
    }

    // **************** BEGIN set of methods to query for a user ****************
   
   // create a getter/setter for the permission set label that is passed in when the user selects the 'Go' button
   public String uName 
   {
        get { return uName;}
        set { uName = value;}
    }

   // get the result from the user query and present it to the user
   public List <User> getUserResults() 
   {
      return queryUser; 
   }
      
   List <User> queryUser;  

   // query permission sets based on the value passed in from the permission set label captured in the page
   public void qU() {
       
    // prevent SOQL Injection - oh no Mr. Bill!
    System.Debug('qU uName = '+uName);
    String queryU = '%' + uName + '%'; 
    System.Debug('qU queryU = '+queryU);
     
    // create query passing in queryLabel from input text in page
    // three where clauses allow you to query on EITHER name *or* title *or* profile
    // this can easily be changed to incorporate other search parameters including custom ones
    // only return one user as the source user to be copied
    queryUser = [SELECT Id, Username, Name, Title, Profile.Name, UserRole.Name
                 FROM User
                 WHERE Name like :queryU
                 OR Title like :queryU
                 OR Profile.Name like :queryU 
                 ORDER by Name
                 LIMIT 1];
   }
  
   // get the result from the user query and present it into the page      
   public PageReference cUsr() 
   {
       // set the user 
       User u = [Select username from User where Id=:queryUser][0];
       
       // pass the new first name, last name, and email into the GeneralCloner class
       GeneralCloner Cloner = new GeneralCloner(u.username);
       Cloner.cloneAndInsert(fname,lname,email);
       
      return null;
   }
   
   List <User> queryClonedUser; 
   
   // get the result from the user query and present it to the user
   public List <User> getCloneResults() 
   {
      String queryCU = '%' + email + '%';
      queryClonedUser = [SELECT Id, Name, Email, Title, Profile.Name, UserRole.Name
                         FROM User
                         WHERE Email like :email];
      return queryClonedUser; 
   }        

}