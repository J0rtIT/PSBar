<#
.Synopsis
   Script that returns scheduled tasks on a computer and gets a clean output in an HTML file
.DESCRIPTION
   This script uses the Schedule.Service COM-object to query the local or a remote computer to gather a formatted list including the Author, UserId, and description of the task. This information is parsed from the XML attributed to providing a more human-readable format. It is necessary to run it as administrative permissions. (Run as Administrator). 
.EXAMPLE
    .\Get-ScheduledTask.ps1
   To run the script against the local Machine, assuming that your computer is called "SVR". this will create the file: TaskInfo-SRV-20170718.html

.EXAMPLE
    .\Get-ScheduledTask.ps1 -Computername MyRemoteMachine
    To run the script on a remote machine (Single remote machine)
    ** Requires an AD CS (a Domain)
    ** Run the script as admin
    Assuming that your remote computer is called "MyRemoteMachine." this will create the file: TaskInfo-MyRemoteMachine-20170718.html

.EXAMPLE
    .\Get-ScheduledTask.ps1 -File .\MyComputers.txt 
    ** Same requirements as example2.
   Assuming that your remote computers are called "Remote1" and "Remote2". This will create the files: TaskInfo-Remote1-20170718.html and TaskInfo-Remote2-20170718.html

.EXAMPLE
    .\Get-ScheduledTaskv3.ps1 -Objs | where{$_.Name -eq "AppleSoftwareUpdate"}

    You can filter by: NextRunTime, Author, Trigger, State, UserId, Actions, Name, LastRunTime, LastTaskResult, Description, NumberOfMissedRuns, Enabled, Path, ComputerName
.EXAMPLE
    .\Get-ScheduledTaskv3.ps1 -Objs | where{$_.Name -eq "AppleSoftwareUpdate"} | ConvertTo-Html | Out-File here.html

    Export to Html.
.INPUTS
    $computername => If you don't provide a name it will run on the localhost.
    $File => File with the names of the Computers, in case you want to run it on several computers

   Switches:
    $RootFolder => Added in original script in version 1.2: "Added the -RootFolder switch, this only gathers the tasks in the root folder instead of all subfolders. This is similar to the behavior of the script in the 1.1 version."
    $Objs => Added so you can get the objects and use them as you want (Filter, csv, json,HTML, etc.)
    $Html => Get HTML File from the original Object. $OBjs
    $Email => Send Emails (required some additional info, From, To, and server)


.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   Name: Get-ScheduledTask.ps1
    Author: Jaap Brasser
    DateCreated: 2012-05-23
    DateUpdated: 2015-03-26
    Site: http://www.jaapbrasser.com
    Version: 1.3

    Enhancement: Jose Ortega
    DateUpdate: 2015/05/13
    Site: https://www.j0rt3g4.com
    Version: 1.4

    Version: 2.0
    Enhancement: Jose Ortega
    DateUpdate: 2017/07/18
    Site: https://www.j0rt3g4.com

    New Features for version 2:
    * Expanded functionality using advanced scripting techniques. (CmdletBinding(), ParameterSets, DefaultParameterSets, Try/Catch, Added Log)
    * Added Log file and messages.
    * Enabled to accept one computer name or a text file with multiple servers/computers (1 server byline).
    * All the previous functionality is still there
    * Updated HTML4 to HTML5

    New Version: Jose Ortega
    DateUpdate: 2017/09/17
    Email: jortega@j0rt3g4.com
    version 3.0

    New Features for version 3:
    * Enable To get Objects from the Cmdlet so you can filter them
    * Enable to export custom objects into the Html file.
    * Updated to the latest version of the JaaS script https://gallery.technet.microsoft.com/scriptcenter/Get-Scheduled-tasks-from-3a377294  (version 1.3.2)
    * Enabled Trigger and Actions objects 
    * Enable to send Email 
    * Enabled Get-Help, with full information (try -Examples)

.LINK
http://www.jaapbrasser.com
https://www.j0rt3g4.com

.COMPONENT
   This cmdlet doesn't belong to any component
.ROLE
   This cmdlet doesn't belong to any role
.FUNCTIONALITY
   Get Objects or HTML report of the Task in your environment
#>
param(
    [CmdletBinding(DefaultParameterSetName="SingleHost")]

    [Parameter(position=0)][Parameter(ParameterSetName='SingleHost',Mandatory=$false)]$computername = "localhost",
    [Parameter(position=1)][Parameter(parameterSetName='MultiHost' ,Mandatory=$true)]$File,
    [Parameter(position=2)][switch]$RootFolder,
    [Parameter(position=3)][switch]$Objs,
    [Parameter(position=4)][switch]$Email,
    #Modify this lines if you want to use your internal email to send emails.
    [Parameter(position=5)][string]$from="info@ceidec.info", #must be within an accepted domain in exchange.
    [Parameter(position=6)][string]$to="info@ceidec.info", #must exists
    [Parameter(position=7)][string]$Server="mail.j0rt3g4.com"
)
#Global variables


#GLOBALs 
$global:ScriptLocation = $(get-location).Path
$global:DefaultLog = "$global:ScriptLocation\ScheduledTasks.log"
$global:Path=$(get-location).Path
$global:AllTheFiles=@()
$global:AllTheObjs=@()

#region Functions
function Write-Log{
    [CmdletBinding()]
    #[Alias('wl')]
    [OutputType([int])]
    Param(
            # The string to be written to the log.
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)] [ValidateNotNullOrEmpty()] [Alias("LogContent")] [string]$Message,
            # The path to the log file.
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,Position=1)] [Alias('LogPath')] [string]$Path=$global:DefaultLog,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,Position=2)] [ValidateSet("Error","Warn","Info","Load","Execute")] [string]$Level="Info",
            [Parameter(Mandatory=$false)] [switch]$NoClobber
    )

     Process{
        
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Warning "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist
        # to create the file include path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Now do the logging and additional output based on $Level
        switch ($Level) {
            'Error' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ERROR: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Warn' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") WARNING: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Info' {
                Write-Host $Message -ForegroundColor Green
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") INFO: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Load' {
                Write-Host $Message -ForegroundColor Magenta
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") LOAD: `t $Message" | Out-File -FilePath $Path -Append
                }
            'Execute' {
                Write-Host $Message -ForegroundColor Green
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") EXEC: `t $Message" | Out-File -FilePath $Path -Append
                }
            }
    }
}
function Get-AllTaskSubFolders {
    [cmdletbinding()]
    param (
        # Set to use $Schedule as default parameter so it automatically list all files
        # For current schedule object if it exists.
        $FolderRef = $Schedule.getfolder("\")
    )
    if ($FolderRef.Path -eq '\') {
        $FolderRef
    }
    if (-not $RootFolder) {
        $ArrFolders = @()
        if(($Folders = $folderRef.getfolders(1))) {
            $Folders | ForEach-Object {
                $ArrFolders += $_
                if($_.getfolders(1)) {
                    Get-AllTaskSubFolders -FolderRef $_
                }
            }
        }
        $ArrFolders
    }
}
function Get-TaskTrigger {
    [cmdletbinding()]
    param (
        $Task
    )
    $Triggers = ([xml]$Task.xml).task.Triggers
    if ($Triggers) {
        $Triggers | Get-Member -MemberType Property | ForEach-Object {
            $Triggers.($_.Name)
        }
    }
}
function Get-TasktsInfo {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline=$True,position=0,mandatory=$true)]$AllFolders
       )
	PROCESS{
		foreach ($Folder in $AllFolders) {
			if (($Tasks = $Folder.GetTasks(1))) {
				$Tasks | Foreach-Object {
                     $xml = [xml]$_.xml;
					New-Object -TypeName PSCustomObject -Property @{
					'Name' = $_.name
					'Path' = $_.path
					'State' = switch ($_.State) {
						0 {'Unknown'}
						1 {'Disabled'}
						2 {'Queued'}
						3 {'Ready'}
						4 {'Running'}
						Default {'Unknown'}
					}
					'Enabled' = $_.enabled
					'LastRunTime' = $_.lastruntime
					'LastTaskResult' = $_.lasttaskresult
					'NumberOfMissedRuns' = $_.numberofmissedruns
					'NextRunTime' = $_.nextruntime
                    'Actions' = ($xml.Task.Actions.Exec | % { "$($_.Command) $($_.Arguments)" }) -join "`n"
					'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author
					'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
					'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
                    'Trigger' = Get-TaskTrigger -Task $_
                    'ComputerName' = $Schedule.TargetServer
					}
				}
			}
		}
	}
	END{
        return $Tasks
	}
}
function Get-TasksInfoHTML {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline=$True,position=0,mandatory=$true)]$AllFolders,
        [Parameter(ValueFromPipeline=$True,position=1,mandatory=$false)]$computer=$env:COMPUTERNAME
        
       )
    BEGIN{
        $tasks =Get-TasktsInfo $AllFolders
        $global:TodayDate= [Datetime]::Now.ToString("yyyyMMdd") # (20170917)
        $global:Time=[Datetime]::Now.ToString("hhmmss") #  (001305)
        $CompName=$computer
        $FnHTML= "TaskInfo-$CompName-$global:TodayDate$global:Time.html"
        $global:AllTheFiles+="$global:Path\$FnHTML"
        $title= "Task Information from $computer on $global:TodayDate // $global:Time"
        $header= "<style type=""text/css"">{margin:0;padding:0}@import url(https://fonts.googleapis.com/css?family=Indie+Flower|Josefin+Sans|Orbitron:500|Yrsa);body{text-align:center;font-family:14px/1.4 'Indie Flower','Josefin Sans',Orbitron,sans-serif;font-family:'Indie Flower',cursive;font-family:'Josefin Sans',sans-serif;font-family:Orbitron,sans-serif}#page-wrap{margin:50px}tr:nth-of-type(odd){background:#eee}th{background:#EF5525;color:#fff;font-family:Orbitron,sans-serif}td,th{padding:6px;border:1px solid #ccc;text-align:center;font-size:large}table{width:90%;border-collapse:collapse;margin-left:auto;margin-right:auto;font-family:Yrsa,serif}</style>";
    }
	END{
    $html5Text="<!DOCTYPE HTML>
<html lang=""en-US"">
<head>
	<meta charset=""UTF-8"">
	<title>" + $title + "</title>
    " + $header + "
</head>
<body>
<h1>" + $title + "</h1>
<table>
<tr><th>Name</th><th>State</th><th>Enabled</th><th>Author</th><th>UserId</th><th>NextRunTime</th><th>LastRunTime</th><th>LastTaskResult</th><th># MissedRuns</th><th>Trigger</th><th>Actions</th><th>Description</th><th>Path</th></tr>
";

foreach($task in $tasks){
    $nm=$task.Name
    $pt=$task.Path
    $st=$task.State
    $en=$task.Enabled
    $missed=$task.NumberOfMissed
    $des=$task.Description
    $aut=$task.Author
    $nt=$task.NextRunTime
    $lt=$task.LastRunTime
    $uid=$task.UserId
    $ltr=$task.LastTaskResult
    $act=$task.Actions
    $tri = $task.Trigger
    $html5Text+="<tr> <td>$nm</td><td>$st</td><td>$en</td><td>$aut</td><td>$uid</td><td>$nt</td><td>$lt</td><td>$ltr</td><td>$missed</td><td>$tri</td><td>$act</td><td>$des</td><td>$pt</td></tr>"
}
	
$html5Text+="
</table>
</body>
</html>"

$html5Text | Out-File "$global:Path\$FnHTML"    
#    Write-Output  $task  | select * | Sort-Object LastRunTime -descending |  ConvertTo-html * -head $header -Title "Task Information from $computer" | Out-File "$path\$FnHTML"
	}
}
#endregion Functions


#Global Variables


Write-Log -Level Info "********************************* STARTING THE SCRIPT *********************************"

try {
    Write-Log -Level Load -message "ParameterSetName in use $($PSCmdlet.ParametersetName)"
    Write-Log -Level Info "Creating the COM object"
	$schedule = new-object -com("Schedule.Service") 
} catch {
    Write-Log -Level Warn "Schedule.Service COM Object not found, this script requires this object. Script will exit now"
    Write-Log -Level Info "********************************* FINISHED THE SCRIPT *********************************"
    exit(-1)
}


if($file){
    Write-Log -Level Info "Getting information from the $file file"
    $computers = Get-Content $File

    foreach($computer in $computers){
        
        try{
            Write-Log -Level Load "Gathering information for $computer"
            if(!($Objs)){
                #Write-Log -Level Load "Gathering information for $computer"
                $Schedule.connect($computer) 
                $AllFolders = Get-AllTaskSubFolders
                Get-TasksInfoHTML $AllFolders $computer
            }

            if($Objs){
                #Write-Log -Level Load "Gathering information for $computer"
                $Schedule.connect($computername) 
                $AllFolders = Get-AllTaskSubFolders
                $tasks =Get-TasktsInfo $AllFolders
                $tasks
            }
        }
        catch{
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Log -Level Error -Message "Message: $ErrorMessage. Make sure that you're running the script as Administrator (in a elevated PS console)"
        }
    }

}
else{
    try{
        #SoloComputername #default
        if($computername -eq "localhost" -and !($Objs)){
            Write-Log -Level Load "Gathering information for $computername"
            $Schedule.connect($ComputerName) 
            $AllFolders = Get-AllTaskSubFolders
            Get-TasksInfoHTML $AllFolders
        }
        
        
        if($computername -eq "localhost" -and $Objs){
            Write-Log -Level Load "Gathering information for $computername"
            $Schedule.connect($computername) 
            $AllFolders = Get-AllTaskSubFolders
            $tasks =Get-TasktsInfo $AllFolders
            $tasks
        }
        else{
            #if it goes this long do a default action
            Write-Log -Level Load "Gathering information for $computername"
            $Schedule.connect($ComputerName) 
            $AllFolders = Get-AllTaskSubFolders
            Get-TasksInfoHTML $AllFolders $computername
        }

    }
    catch{
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Log -Level Error -Message "Message: $ErrorMessage. Make sure that you're running the script as Administrator (in a elevated PS console)"
    }
}


if($Email){
    try{
        if( !($from) -or !($to) -or !($Server)){
            Write-Log -Level Error -Message "When you use the Option -Email, you need to provide 3 more arguments: -from ""email@j0rt3g4.com"" -to ""to@domain.com"" -server ""smtpserver.domain.com"""
        }
        else{
            Send-MailMessage -From $from -To $to -SmtpServer $Server -Attachments $global:AllTheFiles -Subject "Report for $global:TodayDate-$global:Time"
        }
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Log -Level Error -Message "Message: $ErrorMessage. Make sure that you're running the script as Administrator (in a elevated PS console)"
    }
}


Write-Log -Level Info "********************************* FINISHED THE SCRIPT *********************************"