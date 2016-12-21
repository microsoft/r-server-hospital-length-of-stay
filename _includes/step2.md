
1.  First she'll develop R scripts to prepare the data.  To view the scripts she writes, open the files mentioned below.  If you are using Visual Studio, you will see these file in the `Solution Explorer` tab on the right.  In RStudio, the files can be found in the `Files` tab, also on the right. 

    a.  XXXFILE NAME AND DESCRIPTIONS HERE
    
    *You can run these scripts if you wish, but you may also skip them if you want to get right to the modeling.  The data that these scripts create already exists in the SQL database.* 

    In both Visual Studio and RStudio, there are multiple ways to execute the code from the R Script window.  The fastest way for both IDEs is to use Ctrl-Enter on a single line or a selection.  Learn more about  <a href="http://microsoft.github.io/RTVS-docs/">R Tools for Visual Studio</a> or <a href="https://www.rstudio.com/products/rstudio/features/">RStudio</a>.

2.  If you are following along, if you have modified any of the default values created by this solution package you will need to replace the connection string in the **SQL_connection.R** file with details of your login and database name.  
   
       
        connection_string <- "Driver=SQL Server;Server=localhost;Database=Campaign;UID=rdemo;PWD=D@tascience"
        

    *Make sure there are no spaces around the "=" in the connection string - it will not work correctly when spaces are present*

    If you are creating a new database by using these scripts, you must first create the database name in SSMS.  Once it exists it can be referenced in the connection string.  (Log into SSMS using the same username/password you supply in the connection string, or `rdemo`, `D@tascience` if you haven't changed the default values.)

    This connection string contains all the information necessary to connect to the SQL Server from inside the R session. As you can see in the script, this information is then used in the `RxInSqlServer()` command to setup a `sql` string.  The `sql` string is in turn used in the `rxSetComputeContext()` to execute code directly in-database.  You can see this in the **SQL_connection.R** file:

        connection_string <- "Driver=SQL Server;Server=localhost;Database=Campaign;UID=rdemo;PWD=D@tascience"
        sql <- RxInSqlServer(connectionString = connection_string)
        rxSetComputeContext(sql)
      

    
 3.  After running the step1 and step2 scripts, Debra goes to SQL Server Management Studio to log in and view the results of XXXSOMETHING  by running the following query:
        

        SELECT TOP 1000 XXXQUERY HERE


4.  Now she is ready for training the models.  She creates and executes the script you can find in **XXXFILENAME.R**.  XXXIF CHAMPION CHALLENGE: This step will train two different models and evaluate each.  

   The R script draws the ROC or Receiver Operating Characteristic for each prediction model. It shows the performance of the model in terms of true positive rate and false positive rate, when the decision threshold varies. 

    {% include auc.md %}

    Debra will use the AUC to select the champion model to use in the next step.

5.  Finally Debra will create and execute **XXXFILENAME.R** to XXXDO SOMETHING
   *XXXIF NECESSARY: This step may take 10-15 minutes to complete.  Feel free to skip it if you wish, the data already exists in the SQL database.*

6.  Debra will now use PowerBI to visualize the recommendations created from her model.  She creates the PowerBI Dashboard which you can find in the `{{ site.folder_name }}` directory.  She uses an ODBC connection to connect to the data, so that it will always show the most recently modeled and scored data, using the [instructions here](Visualize_Results.html).
  <img src="images/XXvisualize.png">.  If you want to refresh data in your PowerBI Dashboard, make sure to [follow these instructions](Visualize_Results.html) to setup and use an ODBC connection to the dashboard.

7.  A summary of this process and all the files involved is described in more detail [here](data-scientist.html).
