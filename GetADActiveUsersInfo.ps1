
$TimeStart=Get-Date
$today = get-date -format MM-dd-yyyy

function GetPasswordProperties{
    [CmdletBinding()]
    param($path)
 BEGIN{
    Write-Verbose "Importing Active Directory neccesary CMDLETS"
    import-module activedirectory -CMDLet Get-ADUser,SetADUser
    $TodayDate=get-date -UFormat "%Y%m%d" #"%A-%Y%m%d"
    $Fn= "UsersInfo-$TodayDate.csv"
    write-verbose "Getting Script Directory path"
 }
 PROCESS{
    Write-Verbose "Getting information from users"  
    $usersnames= get-aduser -filter * -Properties *
    $AllInfoProperties=@()
    foreach($user in $usersnames){
    $isEnabled=$user.Enabled
    $IDName=$user.SamAccountName
        if($isEnabled -eq $true){
            $AllInfoProperties+=Get-ADUser -Identity $IDName -Properties * | Select DisplayName,SamAccountName,Enabled,EmailAddress,PasswordLastSet,LastLogonDate,LastBadPasswordAttempt,CannotChangePassword,PasswordNeverExpires,logonCount,BadLogonCount|Sort-Object SamAccountName
        }
    }
  

    Write-Verbose "Filtering Results"
    $pwdProp =  $AllInfoProperties|  Select  DisplayName,SamAccountName,Enabled,EmailAddress,PasswordLastSet,LastLogonDate,LastBadPasswordAttempt,CannotChangePassword,PasswordNeverExpires,logonCount,BadLogonCount
       #Where-Object {$_.Installed -eq $true}
    Write-Verbose "Exporting results"
    $pwdProp | Export-csv -path "$path\$Fn" -NoTypeInformation
    #Get-ADUser -filter * -properties Name, SamAccountName,CannotChangePassword,PasswordNeverExpires,PasswordLastSet,LastLogonDate,LastBadPasswordAttempt,BadLogonCount,logonCount | Sort-Object SamAccountName | Export-csv -path "$path\$Fn.csv"
 }
 END{
   # return $pwdProp
 }
 
}

function ShowTimeMS{
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline=$True,position=0,mandatory=$true)]	[datetime]$timeStart,
	[Parameter(ValueFromPipeline=$True,position=1,mandatory=$true)]	[datetime]$timeEnd
  )
  BEGIN {
    
  }
  PROCESS {
		write-Verbose "Stamping time"
		write-Verbose  "initial time: $TimeStart"
		write-Verbose "End time: $TimeEnd"
		$diff=New-TimeSpan $TimeStart $TimeEnd
		Write-verbose "Timediff= $diff"
		$miliseconds = $diff.TotalMilliseconds
		Write-output " Total Time in miliseconds is: $miliseconds ms"
		
  }
}

function Get-ScriptDirectory{
  PROCESS{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
  }
}

$path = Get-ScriptDirectory
GetPasswordProperties $path

#Get the end time 
$TimeEnd=Get-Date

#Show time
ShowTimeMS $timeStart $timeEnd



