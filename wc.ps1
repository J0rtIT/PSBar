<#
    Download XML or JSON item from a URL and query it 
#>

[CmdletBinding()]
param(
    [parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]$HostURI="https://www.w3schools.com/xml/cd_catalog.xml"
)

#Clean Up VariableS
$CleanUpVar=@()
$CleanUpGlobal=@()

$CleanUpVar+="response"
$CleanUpVar+="wc"
$CleanUpVar+="HostURI"
$CleanUpVar+="XmlDoc"
$CleanUpVar+="properties"

[System.Net.WebClient]$wc = New-Object System.Net.WebClient
$response =$wc.DownloadString($HostURI)


[xml]$xmlDoc = New-Object system.Xml.XmlDocument
$xmlDoc.LoadXml($response)

#Now the response of the XML document is in the $xmlDoc object

#Now here's the procesing part (get one or several child)
$properties = $xmlDoc.getElementsByTagName("CD");

#Show All elements in $properties variable
$properties
#foreach($item in $properties){
#    $item.Title
#}

#get the info for finish
$CleanUpVar| ForEach-Object{
	Remove-Variable $_
}
$CleanUpGlobal | ForEach-Object{
	Remove-Variable -Scope global $_
}
Remove-Variable CleanUpGlobal,CleanUpVar

