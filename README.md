## cloneUser

This repo contains a force.com project called CloneUser. CloneUser is designed to meet a fundamental user provisioning request: 

1. I should be able to provision a new user by cloning an existing one. 
2. I should only have to provide the minimal information necessary for the clone to take place. 
3. The new user should include all access right groupings (public groups and permission sets) necessary to get them up and running as soon as possible.

![alt tag] (https://raw.github.com/atorman/cloneUser/master/cloneUserDemo.png)

Specifically, this project provides a set of
VisualForce pages, Apex classes, a permission set, a tabset (app), and a tab that demonstrates one possible way of cloning a user. The Apex classes can and should be reused for other applications as well as extended to include additional child or non-related objects.

This idea has been on the IdeaExchange for a number of years: https://success.salesforce.com/ideaView?id=08730000000BpK9AAK. Typically, this has led to any number of additional interesting hacks such as cloning a user without Apex (http://www.codebycody.com/2013/06/clone-user-in-salesforcecom-without-apex.html) and the idea of a custom clone user button (https://success.salesforce.com/answers?id=90630000000grMNAAY).

## Installation

The easiest way to install this project into your org is to make use of the workbench tool (http://workbench.developerforce.com).  

1. Download a ZIP of the repository. 
2. Open Workbench (http://workbench.developerforce.com/) 
3. Login to the desired organization with a user that has Modify All Data.  
4. Select *Deploy* from the *migration* menu and when prompted, choose your zip file and select 'Allow Missing Files' checkbox before deploying it.
5. If you get an error that the deployment failed because package.xml cannot be found: unzip the cloneUser.zip file you downloaded and use the terminal to re-zip it (e.g. zip -r cloneUser.zip cloneUser) before retrying step 4.


## Configuration and Usage

Assign the CloneUser permission set to any administrator  who should be able to clone users using this utility.

Once this permission set is assigned, they should be able to go to the app, select the tab, and begin cloning. All that is required is a first name, last name, and an email address. Everything else is either assumed or copied from the source user.

## Credit

Most of the Apex code was created by our intern, Ian Dalton, last summer after I pitched the idea for a simple administrative cloning app for cloning users built on top of Apex and VisualForce. I created the VisualForce page and Apex controller that provided a front end user interface for cloning the users. This repo is As-Is. All pull requests are welcome.
