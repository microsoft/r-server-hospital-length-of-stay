Step 5: Use the Model during Admission

The predicted LOS might also be displayed during a patient's admission.  An example of such a display is available in a sample webpage included in this solution.

To try out this example site, you must first start the lightweight webserver for the site. Open a terminal window or powershell window and type the following command.


    cd C:\Solutions\Hospital\Website
    npm start

You should see the following response:


    The website is running at http://localhost:3000
    Tedious-Connection-Pool: filling pool with 2
    Tedious-Connection-Pool: creating connection: 1
    ...

Now leave this window open and open the url http://localhost:3000 in your browser.

This site is set up to mimic a hospital dashboard.  Click on one of the first two patients to view their details.  Select the <code>Admit Patient</code> button to trigger the LOS prediction. The predicted length of stay will appear below the button.

You can view the model values by opening the Console window on your browser.

For Edge or Internet Explorer: Press F12 to open Developer Tools, then click on the Console tab.
For FireFox or Chome: Press Ctrl-Shift-i to open Developer Tools, then click on the Console tab.
Use the Log In button on the site to switch to a different account and try the same transaction again. (Hint: the account number that begins with a “9” is most likely to have a high probability of fraud.)

See more details about this example see [For the Web Developer](web-developer.html).