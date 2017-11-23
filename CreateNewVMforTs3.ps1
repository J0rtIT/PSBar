

########################
#####    Global Variables
################################################

$TimeStart=Get-Date
$global:ScriptLocation = $(get-location).Path
$global:DefaultLog = "$global:ScriptLocation\Vm4Ts3.log"


########################
#####    Functions
################################################
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
        Write-Log -Level Info -Message  "Total Time in miliseconds is: $miliseconds ms"
    }
}
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
function New-JCS-RG{ #new jcs resource group
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='What computer name would you like to target?')][ValidateLength(3,30)][string]$ReGr,
    [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Please get a valid location')][ValidateLength(3,20)][string]$location
  )
  BEGIN{
     New-AzureRmResourceGroup -Name $ReGr -location $location  
  }
  PROCESS{}
  END{}
}
function New-JCS-SA{ #new jcs resource storage account
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the name of the Resource Group')][ValidateLength(3,30)][string]$ReGr,
    [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add a name for the Storage Account')][ValidateLength(3,30)][string]$Name,
    [Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Please get a valid location')][ValidateLength(3,20)][string]$Type,
    [Parameter(Mandatory=$True,position=3,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Please get a valid location')][ValidateLength(3,20)][string]$Location
  )
  BEGIN{
     New-AzureRmStorageAccount -Name $Name -ResourceGroupName $ReGr -Type $Type -Location $location
  }
  PROCESS{}
  END{}
}
function Print-Progress{
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the Progress number')][ValidateRange(0,100)][Int]$Progress,
    [Parameter(Mandatory=$True,position=1,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the add the id associated')][ValidateRange(0,100)][Int]$id,
    [Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the Name associated to the task')][String]$name

    #[Parameter(Mandatory=$True,position=2,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, HelpMessage='Add the name of the Resource Group')][ValidateRange(0,100)][Int]$ProgressParent
    )
  BEGIN{}
  PROCESS{
    if($id -eq 1){
        if($Progress -lt 100){
            write-progress -id $id -activity "$name" -status "$Progress% Complete:" -percentcomplete $Progress
        }
        else{
            write-progress -id $id -activity "$name" -status 100 -percentcomplete 100 -Completed 
        }
    }
    else{
        if($Progress -lt 100){
            write-progress -id $id -ParentId 1 -activity "$name" -status "$Progress% Complete:" -percentcomplete $Progress
        }
        else{
            write-progress -id $id -ParentId 1 -activity "$name" -status 100 -percentcomplete 100 -Completed 
        }
    }
  }
  END{}
}


#Installing/Importing AzureRM

########################
#####    Loading/Installing AzureRM
################################################
Print-Progress -Progress 0 -id 1 -name "General Progress"

$AzureRMisTrue = (Get-Module -Name AzureRM -ListAvailable).Count

Print-Progress -Progress 0 -id 2 -name "Loading/Installing AzureRM"
Write-Log -Level Execute  -Message "Loading/Installing AzureRM"
if($AzureRMisTrue -ne 1){
    Write-Log -Level Info -Message "Installing AzureRM"
	Install-module azurerm
}
else{
    Write-Log -Level Info -Message "Loading AzureRM module"
    write-output "AzureRM Module is installed"
    import-module AzureRM
}

Print-Progress -Progress 100 -id 2 -name "Loading/Installing AzureRM"
Write-Log -Level Execute  -Message "Loading/Installing AzureRM... Done"

Print-Progress -Progress 10 -id 1 -name "General Progress"

Write-Log -Level Execute  -Message "Loggin Into AzureRM"
Print-Progress -Progress 0 -id 3 -name "Login into AzureRM"
Login-AzureRmAccount
#Get-AzureRmSubscription –SubscriptionName "Visual Studio Premium with MSDN" | Select-AzureRmSubscription

Print-Progress -Progress 100 -id 3 -name "Login into AzureRM"
Write-Log -Level Execute  -Message "Loggin Into AzureRM... Done"

Print-Progress -Progress 20 -id 1 -name "General Progress"

########################
#####    Create new ResourceGroup
################################################
Write-Log -Level Execute  -Message "Creating Resource Group $resourceGroup"
Print-Progress -Progress 0 -id 4 -name "Creating Resource Group $resourceGroup"

$resourceGroup = "teamspeak"
$location = "East US 2"
New-JCS-RG -ReGr "$resourceGroup" -Location "$location"
Print-Progress -Progress 100 -id 4 -name "Creating Resource Group $resourceGroup"
Write-Log -Level Execute  -Message "Creating Resource Group $resourceGroup... Done"

Print-Progress -Progress 30 -id 1 -name "General Progress"
########################
#####    Create store account
################################################
$storageAccountName = "teamspeakstg2"
#$sw = [System.Diagnostics.stopwatch]::startnew()

Write-Log -Level Execute  -Message "Creating Storage Account: $storageAccountName"
Print-Progress -Progress 0 -id 5 -name "Creating Storage Account: $storageAccountName"
New-JCS-SA -ReGr $resourceGroup -Name $storageAccountName -Type "Standard_LRS" -location $location
Print-Progress -Progress 100 -id 5 -name "Creating Storage Account: $storageAccountName"

Write-Log -Level Execute  -Message "Creating Storage Account: $storageAccountName... Done"
Print-Progress -Progress 40 -id 1 -name "General Progress"

########################
#####    Virtual Network
################################################

########################  part 1 Subnet(s)
$FEsnName="TS3-SNet"
$vnetName= "TS3-VNet"
Write-Log -Level Execute -Message "Creating Virtual Network: $vnetName"
Print-Progress -Progress 0 -id 6 -name "Creating Virtual Network: $vnetName"

Write-Log -Level Info  -Message "Creating Subnet: $FEsnName"
$subnet1  = New-AzureRmVirtualNetworkSubnetConfig -Name $FEsnName -AddressPrefix 10.11.1.0/28
Write-Log -Level Info  -Message "Creating Subnet: $FEsnName... Done"

########################  part 2  Creating the new vnet
$vnet = New-AzureRmVirtualNetwork -Name "$vnetName" -ResourceGroupName $resourceGroup -Location $location -AddressPrefix 10.11.0.0/16 -Subnet $subnet1
Print-Progress -Progress 100 -id 6 -name "Creating Virtual Network: $vnetName"

Write-Log -Level Execute -Message "Creating Virtual Network: $vnetName... Done"


Print-Progress -Progress 55 -id 1 -name "General Progress"

########################
#####     NSG and rules FrontEnd
################################################
Write-Log -Level Execute -Message "Creating NSG and Rules"


######################## part 1 : Set Inbound Rules
Write-Log -Level Info -Message "Setting Inbound NSG and Rules"
$sshrule   =     New-AzureRmNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 150 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$ts3rule    =    New-AzureRmNetworkSecurityRuleConfig -Name ts3-rule -Description "Allow TS3 Traffic" -Access Allow -Protocol udp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 9987
$SQueryrule =    New-AzureRmNetworkSecurityRuleConfig -Name SrvQuery-rule -Description "Server Query Rule" -Access Allow -Protocol Tcp -Direction Inbound -Priority 250 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 10011
$FileTRule =     New-AzureRmNetworkSecurityRuleConfig -Name FileTransf-rule -Description "File Transfer Rule" -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 30033
$OutBoundInternet = New-AzureRmNetworkSecurityRuleConfig -Name Outbound-free -Description "Allow Internet" -Access Allow -Protocol * -Direction Outbound -Priority 100 -SourceAddressPrefix 10.11.0.0/16 -SourcePortRange * -DestinationAddressPrefix Internet -DestinationPortRange *

Write-Log -Level Info -Message "Setting Inbound NSG and Rules... Done"

######################## part 2 : Set the new Network Security Group and add the rules.
Write-Log -Level Info -Message "Adding the Rules to the Network Security Group"
$NSGName = "NSG-$vnetName" 
Print-Progress -Progress 0 -id 7 -name "Creating Network Security Group: $NSGName"
$nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $NSGName -SecurityRules $sshrule,$ts3rule,$SQueryrule,$FileTRule,$OutBoundInternet
Print-Progress -Progress 100 -id 7 -name "Creating Network Security Group: $NSGName"
Print-Progress -Progress 70 -id 1 -name "General Progress"
Write-Log -Level Info -Message "Adding the Rules to the Network Security Group... Done"

######################## part 3 : Set the NSG to the FrontEnd Virtual Network
Write-Log -Level Info -Message "Adding NSG to the virtual Network: $vnetName"
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $FEsnName -AddressPrefix 10.11.12.0/28 -NetworkSecurityGroup $nsg      
Write-Log -Level Info -Message "Adding NSG to the virtual Network: $vnetName... Done"
######################## part 4 : Save the information of the vnet 
Write-Log -Level Info -Message "Saving the information to the Virtual Network: $vnetName"
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
Write-Log -Level Info -Message "Saving the information to the Virtual Network: $vnetName... Done"

Write-Log -Level Execute -Message "Creating NSG and Rules...Done"


########################
#####    Network VMs devices
################################################
######################## part 1 Create Public IP
Write-Log -Level Execute -Message "Creating NICs for the Virtual Machine"

$nicName="FE-VmNIC"
Print-Progress -Progress 0 -id 8 -name "Creating NICs for Linux VM: $nicName"
#public ip
Write-Log -Level Info -Message "Creating  Public NIC: $nicName"
$Allocation="Static"
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $resourceGroup -location $location -AllocationMethod $Allocation
Write-Log -Level Info -Message "Creating  Public NIC: $nicName... Done"

######################## part 2 Create Internal IP
Write-Log -Level Info -Message "Creating  Internal NIC: $nicName"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
Write-Log -Level Info -Message "Creating  Internal NIC: $nicName... Done"

######################## part 3 Creates the NIC
Write-Log -Level Info -Message "Creating  new NICs"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id 
Print-Progress -Progress 100 -id 8 -name "Creating NICs for Linux VM: $nicName"
Print-Progress -Progress 80 -id 1 -name "General Progress"
Write-Log -Level Info -Message "Creating  new NICs... Done"

Write-Log -Level Execute -Message "Creating NICs for the Virtual Machine... Done"

########################
#Set Credentials for the VM
################################################
Write-Log -Level Execute -Message "Setting Credentials for the VM"

Print-Progress -Progress 0 -id 9 -name "Creating Credentials"
$localUser=$resourceGroup
$localpwd=ConvertTo-SecureString “Passw0rd” -AsPlainText -Force
#before: $cred=Get-Credential -Message "Admin Credentials"
$cred =New-Object System.Management.Automation.PSCredential ($localUser, $localpwd)
Print-Progress -Progress 100 -id 9 -name "Creating Credentials"
Print-Progress -Progress 90 -id 1 -name "General Progress"


Write-Log -Level Warn -Message "Username:$localUser  //    Pwd: Passw0rd "
Write-Log -Level Execute -Message "Setting Credentials for the VM... Done"
########################
#Create VM
################################################
Write-Log -Level Execute -Message "Creating the new VM"
Print-Progress -Progress 0 -id 10 -name "Creating VM"
$vmName ="TS3-InLinux"

######################## Part 1 Name and Size
Write-Log -Level Info -Message "Setting up new VM,  Name: $vmName - Size: Basic_A1"
$vm= New-AzureRmVMConfig -VMName $vmName -VMSize "Basic_A1"
Write-Log -Level Info -Message "Setting up new VM,  Name: $vmName - Size: Basic_A1... Done"


######################## Part 2 new OS 
Write-Log -Level Info -Message "Setting up new VM,  VMOffer from Canonical"
$ubuntuimages=Get-AzureRmVMImageOffer -Location $location -PublisherName 'Canonical'| where{$_.offer -eq "UbuntuServer"}
Write-Log -Level Info -Message "$ubuntuimages"
Write-Log -Level Info -Message "Setting up new VM,  VMOffer from Canonical... Done"

Write-Log -Level Info -Message "Setting up new VM,  Setting credentials into the VM"
$vm= Set-AzureRmVMOperatingSystem -Vm $vm -Linux -ComputerName $vmName -Credential $cred
Write-Log -Level Info -Message "Setting up new VM,  Setting credentials into the VM... Done"


#Create new Source Image:
#check all the publishers available

Write-Log -Level Info -Message "Setting up new VM,  Setting lastest Image"
$Latest = Get-AzureRmVMImage -Location $location  -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "16.04.0-LTS" | select -Last 1
$vm= Set-AzureRmVMSourceImage -VM $vm -PublisherName $Latest.PublisherName -Offer $Latest.Offer -Skus $Latest.Skus -Version $Latest.Version
Write-Log -Level Info -Message "Setting up new VM,  Setting lastest Image $Latest.Version... Done"



#configure source VM disk, Create the VM
Write-Log -Level Info -Message "Setting up new VM,  Adding Nics into the VMs"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
Write-Log -Level Info -Message "Setting up new VM,  Adding Nics into the VMs... Done"


Print-Progress -Progress 94 -id 1 -name "General Progress"

##Create Disk
#Get reference of the account we created before

#Create a full uri where the vhd will be located
Write-Log -Level Info -Message "Setting up new VM,  Creating Disk"
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName 
$diskName="OS-Ldisk"
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage


Write-Log -Level Info -Message "Setting up new VM,  Creating Disk... Done"
#Create the VM

New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm
Print-Progress -Progress 100 -id 10 -name "Creating VM"


Print-Progress -Progress 100 -id 1 -name "General Progress"

$TimeEnd=Get-Date
Write-Log -Level Execute -Message "Creating the new VM... Done"

ShowTimeMS $TimeStart $TimeEnd
#wget http://dl.4players.de/ts/releases/3.0.12.4/teamspeak3-server_linux_amd64-3.0.12.4.tar.bz2
#tar xvf teamspeak3-server_linux_amd64-3.0.12.4.tar.bz2
# cd teamspeak3-server_linux_amd64/
#./ts3server_startscript.sh start




#$wait60=120
#for($i=1; $i -lt $wait60+1;$i++ ){
#	start-sleep -seconds 1
#	$step= 100/$wait60
#	Print-Progress -Progress ($i*$step) -id 6 -name "Waiting 2 min for storage Account to become available: $storageAccountName"
#}