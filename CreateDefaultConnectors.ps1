
<#
Version 2.0
Updated 08/14/2016
This script was updated on 08/14/2016 and 
Solved some bugs with the Check-Connector function
Added Exception Management
Optimized Code 
Logged added


Now it's completely operation on a Exchange server 2013 without or with partials connectors it will detect them and add the ones missing.
#>

#Cleanupvars$CleanUpVar
$CleanUpVar=@() 
$CleanUpGlobal=@() 

#Start time of the script 
$TimeStart=Get-Date 
$CleanUpVar+="TimeStart" 
#Global Variables 
$Global:ScriptLocation = $(get-location).Path 
$Global:DefaultLog = "$global:ScriptLocation\CreateDefaultReceiveConnectors.log" 


function Write-Log{
        [CmdletBinding()]
        #[Alias('wl')]
        [OutputType([int])]
        Param
        (
            # The string to be written to the log.
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)] [ValidateNotNullOrEmpty()] [Alias("LogContent")] [string]$Message,
            # The path to the log file.
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true,Position=1)] [Alias('LogPath')] [string]$Path=$DefaultLog,
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
function ShowTimeMS{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True,position=0,mandatory=$true)]	[datetime]$timeStart,
        [parameter(ValueFromPipeline=$True,position=1,mandatory=$true)]	[datetime]$timeEnd
    )
    BEGIN {}
    PROCESS {
    write-Log -Level Info -Message  "Stamping time"
    
    $diff = New-TimeSpan $TimeStart $TimeEnd
    #Write-Verbose "Timediff= $diff"
    $miliseconds = $diff.TotalMilliseconds
    }
    END{
        return $miliseconds
    }
}
function Check-Connector{
<#
    This function checks if the connector exists and if it's not. It returns true if it's not created and return false if is null
#>
     [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()][parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true,position=0)] $connector,
        [ValidateNotNullOrEmpty()][parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true,position=1)] [int] $parentID
    )

    Begin{
    #Check If connector exists
	write-Log -level info -message "Checking if the connector '$connector' exists"
    Write-Progress -Activity "Checking if the Receive Connector '$connector' exists" -ParentId $parentID -PercentComplete 0
    try{
	    $conn=Get-ReceiveConnector -Identity "$Global:hostname\$connector" -ErrorVariable $errorvar -ErrorAction Stop
        [bool] $Checked = [string]::IsNullOrEmpty( ($conn.Enabled) )
    }
    catch{
        $errorMessage = $_.Exception.Message
		#write-Log -level warn -message "The Connector '$connector' doesn't Exists - $errorMessage"
        $Checked=$true
    }
   
    }
    Process{ }
    End{
		return $Checked
    }


}
function Create-DefaultConnectors{
<#
    Creates default Exchange 2013 Connectors if they doesn't exists.
#>
    [CmdletBinding()]
    param( )

    begin{
		write-Log -level info -message "Creating Default Connectors"
        Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 0
        $range = "0.0.0.0-255.255.255.255","::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
    }

    process{
        Get-TransportService | % {
	      
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Client Proxy $Global:hostname'" -ParentId 1 -id 2 -percentComplete 0
            #CheckConnector
            $isOn=(Check-Connector -connector "Client Proxy $Global:hostname" -parentID 2)
            if($isOn){
				write-Log -level load -message "Creating Connector 'Client Proxy $Global:hostname'"
                New-ReceiveConnector -Name "Client Proxy $Global:hostname" -Bindings 0.0.0.0:465, [::]:465 -AuthMechanism Tls,Integrated,BasicAuth,BasicAuthRequireTLS,ExchangeServer -RemoteIPRanges $range -TransportRole HubTransport -PermissionGroups ExchangeUsers,ExchangeServers -MaxMessageSize 35MB -MessageRateLimit 5 -MessageRateSource User -EnableAuthGSSAPI $True -Server $Global:hostname
            }
            else{
				write-Log -level info -message "This connector is already on the server 'Client Proxy $Global:hostname'"
            }
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Client Proxy $Global:hostname'" -ParentId 1 -id 2 -percentComplete 100 -Completed
            #GeneralProgress
            Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 20


            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Default Frontend $Global:hostname'" -ParentId 1 -id 3  -percentComplete 0
            #CheckConnector
            $isOn=(Check-Connector -connector "Default Frontend $Global:hostname" -parentID 3)
            if($isOn){
				write-Log -level load -message "Creating Connector 'Default Frontend $Global:hostname'"
                New-ReceiveConnector -Name "Default Frontend $Global:hostname" -Bindings 0.0.0.0:25, [::]:25 -AuthMechanism Tls,Integrated,BasicAuth,BasicAuthRequireTLS,ExchangeServer -RemoteIPRanges $range -TransportRole FrontendTransport -PermissionGroups AnonymousUsers,ExchangeServers,ExchangeLegacyServers -MaxMessageSize 36MB -DomainSecureEnabled $True -ProtocolLoggingLevel Verbose -Server $Global:hostname
            }
            else{
				write-Log -level info -message "This connector is already on the server 'Default Frontend $Global:hostname'"
            }
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Default Frontend $Global:hostname'" -ParentId 1 -id 3 -percentComplete 100 -Completed
            #GeneralProgress
            Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 40
            
            
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Outbound Proxy Frontend $Global:hostname" -ParentId 1 -id 4 -percentComplete 0
            #CheckConnector
            $isOn=(Check-Connector -connector "Outbound Proxy Frontend $Global:hostname" -parentID 4)            
            if($isOn){
				write-Log -level load -message "Creating Connector 'Outbound Proxy Frontend $Global:hostname"
                New-ReceiveConnector -Name "Outbound Proxy Frontend $Global:hostname" -Bindings 0.0.0.0:717, [::]:717 -AuthMechanism Tls,Integrated,BasicAuth,BasicAuthRequireTLS,ExchangeServer -RemoteIPRanges $range -TransportRole FrontendTransport -PermissionGroups ExchangeServers -MaxMessageSize 36MB -DomainSecureEnabled $True -ProtocolLoggingLevel Verbose -Server $Global:hostname
            }
            else{
				write-Log -level info -message "This connector is already on the server 'Outbound Proxy Frontend $Global:hostname'"
            }
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Client Proxy $Global:hostname'" -ParentId 1 -id 4 -percentComplete 100 -Completed
            #GeneralProgress
            Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 60


            #ParticularProgress
            Write-Progress -Activity "Client Frontend $Global:hostname" -ParentId 1 -id 5 -percentComplete 0
            #CheckConnector
            $isOn = Check-Connector -connector "Client Frontend $Global:hostname" -parentID 5
            if($isOn){
				write-Log -level load -message "Client Frontend $Global:hostname"
                New-ReceiveConnector -Name "Client Frontend $Global:hostname" -Bindings 0.0.0.0:587, [::]:587 -AuthMechanism Tls,Integrated,BasicAuth,BasicAuthRequireTLS -RemoteIPRanges $range -TransportRole FrontendTransport -PermissionGroups ExchangeUsers -MaxMessageSize 35MB -MessageRateLimit 5 -MessageRateSource User -EnableAuthGSSAPI $True -Server $Global:hostname
            }
            else{
				write-Log -level info -message "This connector is already on the server 'Client Frontend $Global:hostname'"
            }
            #ParticularProgress
            Write-Progress -Activity "Client Frontend $Global:hostname" -ParentId 1 -id 5 -percentComplete 100 -Completed
            #GeneralProgress
            Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 80
            


            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Default $Global:hostname'" -ParentId 1 -id 6 -percentComplete 0
            #CheckConnector
            $isOn = Check-Connector -connector "Default $Global:hostname" -parentID 6
            if($isOn){
				write-Log -level load -message "Creating Connector 'Default $Global:hostname'"
                New-ReceiveConnector -Name "Default $Global:hostname" -Bindings [::]:2525, 0.0.0.0:2525 -AuthMechanism Tls,Integrated,BasicAuth,BasicAuthRequireTLS,ExchangeServer -RemoteIPRanges $range -TransportRole HubTransport -PermissionGroups ExchangeUsers,ExchangeServers,ExchangeLegacyServers -MaxMessageSize 35MB -MaxInboundConnectionPerSource Unlimited -MaxInboundConnectionPercentagePerSource 100 -MaxRecipientsPerMessage 5000 -SizeEnabled EnabledWithoutValue -Server $Global:hostname
            }
            else{
				write-Log -level info -message "This connector is already on the server 'Default $Global:hostname'"
            }
            #ParticularProgress
            Write-Progress -Activity "Creating Connector 'Default $Global:hostname'" -ParentId 1 -id 6 -percentComplete 100 -Completed
            #GeneralProgress
            Write-Progress -Activity "Creating Default Connectors in Exchange Server 2013" -id 1 -percentComplete 100 -Completed
        }
    
    }

    end{
        Write-Output "Finished main function"
    }
}

$CleanUpGlobal+="ScriptLocation" 
$CleanUpGlobal+="DefaultLog" 
$CleanUpGlobal+="hostname" 


Write-Verbose "Importing Exchange server Management Console" 
Write-Log -Level Info "Cheking if the Exchange PS Snap in is present" 
if ( (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue) -eq $null ){ 
    Write-Log -Level Load "Loading Exchange PS Snap in" 
	try{
		#Add-PSSnapin Microsoft.Exchange.*  -ErrorAction SilentlyContinue| Out-Null
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction Stop
	}
	catch{
	$msg = $_.Exception.Message
		write-output "The Exchange Tools aren't installed, Can't continue, Exception Message: $msg"
		Write-Log -Level Error "The Exchange Tools aren't installed, Can't continue, Exception Message: $msg"
		break
	}
} 
else{ 
    Write-log -Level Warn "Exchange PS Snapin is already loaded" 
} 


$Global:hostname= Get-TransportService | % {$_.Name}


#call main fnction
Create-DefaultConnectors

$TimeEnd =Get-Date 
$totalms=ShowTimeMS $TimeStart $TimeEnd 
    
write-Log -level Info -Message "Finished Script in $totalms miliseconds"	

#Clean Up 
  Write-Log -Level Info "Cleaning up variables" 
 
$CleanUpVar| ForEach-Object{ 
    Remove-Variable $_ 
    } 
$CleanUpGlobal | ForEach-Object{ 
    Remove-Variable -Scope global $_ 
} 
Remove-Variable CleanUpGlobal,CleanUpVar 











