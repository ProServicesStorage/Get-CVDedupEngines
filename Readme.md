The following custom report lists all of the deduplication engines across multiple CommCells and includes Deduplication Engine Name, Size on Media, Application Size, Q&I, Q&I for 14 days, Partition Count, and Pending Deletes. In addition, the report highlights when 14 day Q&I is over 1000 and further indicate when it is over 1700. 
 
This Powershell script creates an html report across multiple CommCells that highlights in red when Q&I is over 1700 and yellow when it is over 1000. These thresholds were requested by the customer but could easily be modified in the script.  In addition to the requested columns the % deduplication savings is included. Last, an MA sizing reference summary section is included at the bottom as a cross-reference point when analyzing areas of concern.
 
To run, create a directory called D:\CVPS_Scripts. The directory can be modified by changing the input variable for the function CreateBaseFolders. Create a text file called commcells.txt with one commcell per line. The commcell should be specified as the CommServe SQL database Instance which may reflect a different name than the commcell name. The script utilizes the logged in user's credentials. We ran with the script logged in as local admin and SQL sysadmin, however, it certainly may be possible to utilize reduced SQL privileges. 
 
commcells.txt ex.

CommServe1\Commvault

CommServe2\Commvault

CommServe3\Commvault
 
The script creates a subdirectory called reports which contains the report output. Each report is timestamped and thus unique. In addition, a log subdirectory is created to output any sqlcmd errors.

 
