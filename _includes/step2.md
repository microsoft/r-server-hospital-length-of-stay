
1.  First she'll develop R scripts to prepare the data.  To view the scripts she writes, open the files mentioned below.  If you are using Visual Studio, you will see these file in the `Solution Explorer` tab on the right.  In RStudio, the files can be found in the `Files` tab, also on the right. 

    * **step1_data_preprocessing.R**
    * **step2_feature_engineering.R**
    
    *You can run these scripts if you wish, but you may also skip them if you want to get right to the modeling.  The data that these scripts create already exists in the SQL database.* 

    In both Visual Studio and RStudio, there are multiple ways to execute the code from the R Script window.  The fastest way for both IDEs is to use Ctrl-Enter on a single line or a selection.  Learn more about  <a href="http://microsoft.github.io/RTVS-docs/">R Tools for Visual Studio</a> or <a href="https://www.rstudio.com/products/rstudio/features/">RStudio</a>.

          
3.  After running the step1 and step2 scripts, Debra goes to SQL Server Management Studio to log in and view the results of these steps  by running the following query:
        

        SELECT TOP 1000 *    FROM [Hospital].[dbo].[LoS]

4.  Now she is ready for training the models.  She creates and executes the following script to train and score  a regression Random Forest (rxDForest) and a gradient boosted trees model (rxFastTrees) on the training set. This uses the new [MicrosoftML package](https://msdn.microsoft.com/en-us/microsoft-r/microsoftml-introduction) for Microsoft R Server (version 9.0.1). Both models will  predict LOS.  When she looks at the metrics of both models, she notices that along with a faster performance time, the rxFastTrees model also performs with lower error, so she decides to use this model for prediction.  

    *  **step3_training_evaluation**


6.  Debra will now use PowerBI to visualize the predictions created from her model.  She creates the PowerBI Dashboard which you can find in the `{{ site.folder_name }}` directory.  If you want to refresh data in your PowerBI Dashboard, make sure to [follow these instructions](Visualize_Results.html) to provide the necessary information.

7.  A summary of this process and all the files involved is described in more detail [here](data-scientist.html).
