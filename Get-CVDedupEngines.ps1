#Powershell script created on 12/8/2019 by Mark Richardson
#Creates html report showing dedupe engines and certain values
#Creates the report in D:\CVPS_Scripts\Reports. Modify CreateBaseFolders path to change.

#Create base folders if not already there
Function CreateBaseFolders
{
param([string]$p="C:\CVPS_Scripts")


$global:Logfolder = $p+"\log"
if (Test-Path $global:Logfolder) {
}
Else {
    md $global:Logfolder
}


$global:RunFolder = $p
if (Test-Path $global:RunFolder) {
}
Else {
    md $global:RunFolder
}

$global:ReportFolder = $p+"\Reports"
if (Test-Path $global:ReportFolder) {
}
Else {
    md $global:ReportFolder
}
}

#Modify if necessary. Root folder where log and reports folders get created.
CreateBaseFolders "D:\CVPS_Scripts"

#Set some variables
$date = get-date -uformat %d-%m-%Y-%H.%M.%S
$outputfile = $ReportFolder+"\CVDedupeEngines_"+$date+".html"
$outputfileSQL = $RunFolder+"\tempCVSql.txt"
$MessageHeader = "List of Deduplication Engines for CommCell:"
$commCellInputFile = $RunFolder+"\commcells.txt"
$commCells = get-content $commCellInputFile
$logfile = $Logfolder+"\Get-CVDedupEngines.log"
$Timestamp = Get-Date -Format "dddd MM/dd/yyyy HH:mm:ss"
$customErrorSQL = "SQL Error for CommCell: "

#Create html header and style stuff. Use Commvault color codes
"<!DOCTYPE html>" | out-file -FilePath $outputfile -Append
"<html>" | out-file -FilePath $outputfile -Append
"<head>" | out-file -FilePath $outputfile -Append
"<title>Commvault Deduplication Engine List</title>" | out-file -FilePath $outputfile -Append
"</head>" | out-file -FilePath $outputfile -Append
"<style>" | out-file -FilePath $outputfile -Append
"table, TD, TH {border: 1px solid #000000; }" | out-file -FilePath $outputfile -Append
"table, TD, TH {border-radius: 2px; }"  | out-file -FilePath $outputfile -Append
"table {padding: 1px;}" | Out-File -FilePath $outputfile -Append
"p, TD {color: #0B2E44; }" | out-file -FilePath $outputfile -Append
"a:link  {color: 0047BB; }" | out-file -FilePath $outputfile -Append
"a:visited  {color: #FF4A6A; }" | out-file -FilePath $outputfile -Append
"a:hover  {color: #FFBF3C; }" | out-file -FilePath $outputfile -Append
"HR {border: 1px solid #DDE5ED; }" | out-file -FilePath $outputfile -Append
"TH {background: #0B2E44; }" | out-file -FilePath $outputfile -Append
"TH {color: #FFFFFF; }" | out-file -FilePath $outputfile -Append
"legend {font-weight: bold;}" | out-file -FilePath $outputfile -Append 
"fieldset {background:#DDE5ED;border:1px solid black;}" | out-file -FilePath $outputfile -Append
"</style>" | out-file -FilePath $outputfile -Append
"<body>" | out-file -FilePath $outputfile -Append
"<H1 align=`"center`">List of Commvault Deduplication Engines</H1>" | out-file -FilePath $outputfile -Append
"<HR>" | out-file -FilePath $outputfile -Append


Function TableDedupEngines {
    foreach ($commCell in $commCells) { 
        #$commCell
        #Get data from Commvault CommServ database
        Try {
        Invoke-sqlcmd -ServerInstance "$commCell" -Database CommServ -Query "exec MMGetDDBEngines 0, 5, 0, 0, 0, 1048" > $outputfileSQL
        echo "`n"
        $Timestamp | out-file -FilePath $logfile -Append
        "Successful connection to $commcell" | out-file -FilePath $logfile -Append  
        }
        catch{
          $Timestamp | out-file -FilePath $logfile -Append
          $customErrorSQL+$commCell
          $customErrorSQL+$commCell | out-file -FilePath $logfile -Append
          $MyErrorSQL = $Error[0]
          $MyErrorSQL | out-file -FilePath $logfile -Append

        }

        $inputfile = get-content $outputfileSQL

        Try {
        $CCNameT = Invoke-sqlcmd -ServerInstance "$commCell" -Database CommServ -Query "select aliasName from APP_CommCell where id = 2"
        $CommCellName = $CCNameT[0]
        $MessageHeader+" "+$CommCellName
        }
        catch{
          $Timestamp | out-file -FilePath $logfile -Append
          $customErrorSQL+$commCell
          $customErrorSQL+$commCell | out-file -FilePath $logfile -Append
          $MyErrorSQL = $Error[0]
          $MyErrorSQL | out-file -FilePath $logfile -Append
          $CommCellName = $commCell
          #$lk =$commCell.Split("{\}")
          #$CommCellName = $lk[1..($lk.Length-1)]
        }
        
        #Create html and table headers

        "<H2 align=`"center`">CommCell:"+$CommCellName+"</H2>" | out-file -FilePath $outputfile -Append

        "<table style=`"width:100%`">" | out-file -FilePath $outputfile -Append
        "<TR>" | out-file -FilePath $outputfile -Append
        "<TH>DDB Engine Name</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Size After Dedupe (TB)</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Size Before Dedupe (TB)</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Number of Partitions</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Avg Q&I Time</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Avg Q&I Time for 14 days</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Dedupe % Savings</TH>" | out-file -FilePath $outputfile -Append
        "<TH>Pending Deletes</TH>" | out-file -FilePath $outputfile -Append
        "</TR>" | out-file -FilePath $outputfile -Append

      #Output specific columns from raw sql query
      foreach ($line in $inputfile) { 

         #Get pending deletes
             if ($line -match "SIDBStoreId") {
                Try {
                        $rrr =$line.Split("{:}")
                        $arr3 = $rrr[1..($rrr.Length-1)]
                        $sqlquery="select top 1 ZeroRefCount from IdxSIDBUsageHistory where SIDBStoreId='$arr3' order by ModifiedTime desc"
                        $PendingDeletes = Invoke-sqlcmd -ServerInstance "$commCell" -Database CommServ -Query $sqlquery
                        $Pend = $PendingDeletes[0]
                        "<TR>" | out-file -FilePath $outputfile -Append
                        $rty = "<TD>"+$Pend+"</TD>" 
                               
                    }
                catch {
                        $Pend="NA"
                        "<TR>" | out-file -FilePath $outputfile -Append
                        $rty = "<TD>"+$Pend+"</TD>"
                    }
                }

             #Get DDB Name
             elseif ($line -match "SIDBStoreName") {
                    $y =$line.Split("{:}")
                    $arr = $y[1..($y.Length-1)]
                    #Join as one line again as name contains : maybe so split puts into separat lines
                    $yt = [String]::Join(':', $arr)
                    $yt
                   "<TD>"+$yt+"</TD>" | out-file -FilePath $outputfile -Append
            }
    
            #Get App Size and Size on Media size in TB
            elseif (($line -match "sizeOnMedia")  -or ($line -match "totalAppSize")) {

                $r =$line.Split("{:}")
                $arr2 = $r[1..($r.Length-1)]
                $nn = [String]::Join('', $arr2)
                $nn = $nn / 1024 / 1024 /1024 /1024
                $nn = [Math]::Round($nn,2)

                "<TD>"+$nn+"</TD>" | out-file -FilePath $outputfile -Append
            }
             #Get number of ddb partitions
             elseif ($line -match "SubStoreCount") {
                $r =$line.Split("{:}")
                $arr2 = $r[1..($r.Length-1)]
                [String]::Join('', $arr2) | Out-Null
                "<TD>"+$arr2+"</TD>" | out-file -FilePath $outputfile -Append
            }
             #Get Q&I for last 14 days
             elseif ($line -match "AvgQITime14Days") {
                $r =$line.Split("{:}")
                $arr2 = $r[1..($r.Length-1)]
                $mm = [String]::Join('', $arr2)
                $mmi = [int]$mm
                #If Q&I is greater than 1700 red and bad
                if ($mmi -gt 1700) {
                    "<TD bgcolor=`"#FF4A6A`">"+$mm+"</TD>" | out-file -FilePath $outputfile -Append
                }
                #If Q&I is greater between 1000-1700 then yellow and warning
                elseif (($mmi -gt 1000) -and ($mmi -lt 1700)) {
                    "<TD bgcolor=`"#FFBF3C`">"+$mm+"</TD>" | out-file -FilePath $outputfile -Append
                }
                #If Q&I is less than 1000 than green
                elseif ($mmi -lt 1000 ){
                    "<TD bgcolor=`"#00B2A9`">"+$mm+"</TD>" | out-file -FilePath $outputfile -Append
                }
        
            }

             #Get Q&I
             elseif (($line -match "AvgQITime") -and ($line -notmatch "MaxAvgQITime")) {
                $r =$line.Split("{:}")
                $arr2 = $r[1..($r.Length-1)]
                [String]::Join('', $arr2) | Out-Null
                "<TD>"+$arr2+"</TD>" | out-file -FilePath $outputfile -Append
            }
    
             #Get % dedupe savings
             elseif ($line -match "deDupSavingPercent") {
                $r =$line.Split("{:}")
                $arr2 = $r[1..($r.Length-1)]
                [String]::Join('', $arr2) | Out-Null
                "<TD>"+$arr2+"</TD>" | out-file -FilePath $outputfile -Append
                
                #output pending deletes to last column. I know kinda weird!
                $rty | out-file -FilePath $outputfile -Append
                "</TR>" | out-file -FilePath $outputfile -Append
            }
}
    #end of table
    "</table>" | out-file -FilePath $outputfile -Append
 
    
    #cleanup time. Remove temporary SQL file
    rm $outputfileSQL
    }
   
} #end function LoopCommCells
Function CreateDedupReferenceTable {

#Reference Table
"</TR>" | out-file -FilePath $outputfile -Append
"</table>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<br>" | out-file -FilePath $outputfile -Append
"<fieldset>" | out-file -FilePath $outputfile -Append
 "<legend>Deduplication Sizing Reference</legend>" | out-file -FilePath $outputfile -Append
 "<p>For current and more detailed information see <a href=`"http://documentation.commvault.com/commvault/v11/article?p=99175.htm`">Commvault Sizing Documentation</a></p>" | out-file -FilePath $outputfile -Append
 "<p>OS should be 400 GB SSD for on-premise MediaAgents. It is recommended to use dedicated volumes for index cache disk and DDB disk. Assumes standard retention of up to 90 days.</p>" | out-file -FilePath $outputfile -Append
 "<p><b>AWS:</b> <a href=`"https://cloud.kapostcontent.net/pub/ef27d419-7cd3-4602-b8e7-81559427c6da/public-cloud-architecture-guide-for-aws-v11-sp15?kui=gK2pXAdsW6lUvhjRWz28VA`">More information</a> on sizing AWS MediaAgents.</p>" | out-file -FilePath $outputfile -Append
 "<p><b>Azure:</b> <a href=`"https://cloud.kapostcontent.net/pub/dd4cc546-5463-43a1-acf9-3a1204ae1cc0/commvault-cloud-architecture-guide-for-microsoft-azure?kui=bW1q3B9AkloFbSG8GsCbXQ`">More information</a> on sizing Azure MediaAgents.</p>" | out-file -FilePath $outputfile -Append 
 "<p>FET = Size of the data (for example, files, database, and mailboxes) on the client computer that have to be backed up. Basically, the size of one full backup with no compression</p>" | out-file -FilePath $outputfile -Append
 "<p>BET = Size of all data compressed in Commvault once protected. </p>"  | out-file -FilePath $outputfile -Append
 "<p>Cloud Sizing based off size <b>Large</b></p>"  | out-file -FilePath $outputfile -Append

 "<h4>Cloud MediaAgent Sizing</h4>"  | out-file -FilePath $outputfile -Append
 
 "<table>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<th>Size</th>" | out-file -FilePath $outputfile -Append
     "<th>Type</th>" | out-file -FilePath $outputfile -Append
     "<th>CPU Count</th>" | out-file -FilePath $outputfile -Append
     "<th>RAM</th>" | out-file -FilePath $outputfile -Append
     "<th>DDB Disk</th>" | out-file -FilePath $outputfile -Append
     "<th>DDB Disk IOPS</th>" | out-file -FilePath $outputfile -Append
     "<th>Index Cache Disk</th>" | out-file -FilePath $outputfile -Append
     "<th>4 Partition FET</th>" | out-file -FilePath $outputfile -Append
     "<th>4 Partition BET</th>" | out-file -FilePath $outputfile -Append
     "<th>2 Partition FET</th>" | out-file -FilePath $outputfile -Append
     "<th>2 Partition BET</th>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<td>AWS</td>" | out-file -FilePath $outputfile -Append
     "<td>r5.2Large</td>" | out-file -FilePath $outputfile -Append
     "<td>8</td>" | out-file -FilePath $outputfile -Append
     "<td>64 GB</td>" | out-file -FilePath $outputfile -Append
     "<td>1.2 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>EBS Provisioned IOPS at 15K</td>" | out-file -FilePath $outputfile -Append
     "<td>1 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>960 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>2400 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>480 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>1200 TB</td>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<td>Azure</td>" | out-file -FilePath $outputfile -Append
     "<td>Standard_D16s_v3</td>" | out-file -FilePath $outputfile -Append
     "<td>16</td>" | out-file -FilePath $outputfile -Append
     "<td>64 GB</td>" | out-file -FilePath $outputfile -Append
     "<td>1.2 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>Premium Storage (Type P40) at 7.5K IOPS</td>" | out-file -FilePath $outputfile -Append
     "<td>1 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>960 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>2400 TB</td>"| out-file -FilePath $outputfile -Append
     "<td>150 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>500 TB</td>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
 "</table>" | out-file -FilePath $outputfile -Append

 "<h4>On-Premise MediaAgent Sizing</h4>"  | out-file -FilePath $outputfile -Append
 
 "<table>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<th>Size</th>" | out-file -FilePath $outputfile -Append
     "<th>CPU Count</th>" | out-file -FilePath $outputfile -Append
     "<th>RAM</th>" | out-file -FilePath $outputfile -Append
     "<th>DDB Disk</th>" | out-file -FilePath $outputfile -Append
     "<th>DDB Disk IOPS</th>" | out-file -FilePath $outputfile -Append
     "<th>Index Cache Disk</th>" | out-file -FilePath $outputfile -Append
     "<th>4 Partition FET</th>" | out-file -FilePath $outputfile -Append
     "<th>4 Partition BET</th>" | out-file -FilePath $outputfile -Append
     "<th>2 Partition FET</th>" | out-file -FilePath $outputfile -Append
     "<th>2 Partition BET</th>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<td>Large</td>" | out-file -FilePath $outputfile -Append
     "<td>12</td>" | out-file -FilePath $outputfile -Append
     "<td>64 GB</td>" | out-file -FilePath $outputfile -Append
     "<td>1.2 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>15K</td>" | out-file -FilePath $outputfile -Append
     "<td>1 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>240 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>600 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>120 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>300 TB</td>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
   "<tr>" | out-file -FilePath $outputfile -Append
     "<td>X-Large</td>" | out-file -FilePath $outputfile -Append
     "<td>16</td>" | out-file -FilePath $outputfile -Append
     "<td>128 GB</td>" | out-file -FilePath $outputfile -Append
     "<td>2 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>20K</td>" | out-file -FilePath $outputfile -Append
     "<td>2 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>300 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>1000 TB</td>"| out-file -FilePath $outputfile -Append
     "<td>150 TB</td>" | out-file -FilePath $outputfile -Append
     "<td>500 TB</td>" | out-file -FilePath $outputfile -Append
   "</tr>" | out-file -FilePath $outputfile -Append
 "</table>" | out-file -FilePath $outputfile -Append
"</fieldset>" | out-file -FilePath $outputfile -Append
"</body" | out-file -FilePath $outputfile -Append
"</html>" | out-file -FilePath $outputfile -Append

} #end function CreateReferenceTable


#Call Main Functions
TableDedupEngines
CreateDedupReferenceTable

#Get out of SQL.
cd $PSScriptRoot

#End of Script