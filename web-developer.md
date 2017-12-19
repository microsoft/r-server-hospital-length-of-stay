---
layout: default
title: For the Web Developer
---

## For the Web Developer
------------------------------
<div class="row">
    <div class="col-md-6">
        <div class="toc">
          <li><a href="#starting">Starting the Website</a></li>
          <li><a href="#scoring">Predicting LOS</a></li>
          <li><a href="#remoteaccess">Remote Access to Website</a></li>

        </div>
    </div>
    <div class="col-md-6">

    The example site is built with <a href="https://nodejs.org/en/">node.js</a>.  It uses <a href="http://tediousjs.github.io/tedious/">tedius</a> for communication with SQL Server.  

    </div>
</div>

Now that we know how to predict LOS, we might want to use this in real time when a patient is admitted to a hospital.  This example webpage shows how you can connect to the SQL Server and perform native scoring to obtain a predicted length of stay for a patient.

<a id="starting" />

<h2>Starting the Website</h2>
<hr/>
To start the sample webpage, type the following commands into  a terminal window or powershell window.  Substitute your own values for <span class="onp">the path and </span> username/password:

```
    cd C:\Solutions\Hospital\Website
    npm start
```

You should see the following response:

```
    The website is running at http://localhost:3000
    Tedious-Connection-Pool: filling pool with ...
```

Now leave this window open and open the url [http://localhost:3000](http://localhost:3000) in your browser.  

Or see below for <a href="#remoteaccess">accessing the website from a different computer</a>

<a id="scoring" />
<h2>Prediction LOS</h2>
<hr/>

A connection to the `Hospital_R` database is set up in  **server.js**.  If you deployed the solution from the Cortana Intelligence Gallery, the user name and password you chose has been inserted as well.  Otherwise, open the file and supply your SQL username and password.

```javascript
    var connectionConfig = {
    userName: 'XXYOURSQLUSER',
    password: 'XXYOURSQLPW)rd12',
    server: 'localhost',
    options: { encrypt: true, database: 'Hospital_R' }
```

The `predict` function then calls the `do_native_predict` stored procedure with the patient id and receives back a predicted length of stay for that patient.

```javascript
    app.get('/predict', function (req, res) {
    pool.acquire(function (err, con) {
    if (err) {
      console.error(err);
      con.release();
      return;
    }

    var request = new Request('do_native_predict', function (err, rowCount) {
      if (err) {
        console.log(err);
        con.release();      
        return;
      }
      con.release();
    });

    var eid = req.query.eid;
    console.log('Patient ID: ' + eid)
    request.on('row', function (col) {
      if (col[0].value === null) {
        console.log('NULL result');
      } else {
        // value to return - the predicted LOS
        value = col[0].value;
      }
      res.json({ pred: value });
      console.log("Prediction: " + value)
    });

    // pass the eid to the stored procedure
    request.addParameter('eid', TYPES.VarChar, eid);
    con.callProcedure(request);
  });

});
```

Finally, the function in  **public/js/predLOS.js** uses this prediction to display a message to the user based on the value:

```javascript
function predLOS (id) {
    // call /predict to get res.pred, the predicted LOS
    $.ajax({
        url: '/predict',
        type: 'GET',
        data: { eid: id },
        contentType: "application/json; charset=utf-8",
        error: function (xhr, error) {
            console.log(xhr); console.log(error);
        },
        success: function (res) {
            console.log("PatientID: " + id)
            console.log("Predicted LOS: " + res.pred)
            // now display the result
            los = Math.round(res.pred);
            showResult(los);

        }

    });  
}
```


<a id="example" />
<h2> Admitting a Patient</h2>
<hr/>

This site is set up to mimic a hospital dashboard.  Click on one of the first two patients to view their details.  Select the <code>Admit Patient</code> button to trigger the LOS prediction. 

You can view the model values by opening the Console window on your browser.

* For Edge or Internet Explorer: Press `F12` to open Developer Tools, then click on the Console tab.
* For FireFox or Chome: Press `Ctrl-Shift-i` to open Developer Tools, then click on the Console tab.



<div id="remoteaccess">
<h2> Remote Access to Website</h2>
<hr/>

If you wish to access this website from another computer, perform the following steps;

<li>  Open the firewall for port 3000:
<div class="highlighter-rouge"><pre class="highlight"><code> 
     netsh advfirewall firewall add rule name="website" dir=in action=allow protocol=tcp localport=3000 
</code></pre></div>
</li>
<li>  Then start the web server:
<div class="highlighter-rouge"><pre class="highlight"><code> 
    cd C:\Solutions\Fraud\Website
    npm start
</code></pre></div>
</li>
<li> On other computers, use the Public IP Address in place of <code>localhost</code> in the address http://<strong>localhost</strong>:3000.  The Public IP Address  can be found in the Azure Portal under the "Network interfaces" section.
</li>
<li> Make sure to leave the terminal window in which you started the server open on your VM.
</li>
</div>