#Requires -Version 1
Set-StrictMode -Version Latest
$SystemFunctions = Get-ChildItem function:
$PublicCommands = "^(Get|Switch).+"
$Namespaces = @{env = "http://schemas.xmlsoap.org/soap/envelope/"}

Function Switch-WLAN([String] $Hostname = "fritz.box",
                     [Int]    $WlanId = 3,
                     [String] [Parameter(Mandatory=$True)] $Username,
                     [String] [Parameter(Mandatory=$True)] $Password,
                     [String] [Parameter(Mandatory=$True)] [ValidateSet("true", "false")] $Enable) {
  Call-SoapService -Endpoint "http://$($Hostname):49000/upnp/control/wlanconfig$($WlanId)" `
                   -Username $Username `
                   -Password $Password `
                   -ActionURI "urn:dslforum-org:service:WLANConfiguration:$($WlanId)" `
                   -ActionCommand "SetEnable" `
                   -CommandKey "NewEnable" `
                   -CommandValue $Enable `
  | Unwrap-XmlContent
}

Function Get-CallList([String] $Hostname = "fritz.box",
                      [Int]    $CallListId = 1,
                      [String] [Parameter(Mandatory=$True)] $Username,
                      [String] [Parameter(Mandatory=$True)] $Password) {
  Call-SoapService -Endpoint "http://$($Hostname):49000/upnp/control/x_contact" `
                   -Username $Username `
                   -Password $Password `
                   -ActionURI "urn:dslforum-org:service:X_AVM-DE_OnTel:$($CallListId)" `
                   -ActionCommand "GetCallList" `
  | Unwrap-XmlContent
  
}

Function Get-SecurityPort([String] [Parameter(Mandatory=$False)] $Hostname = "fritz.box",
                          [Int]    [Parameter(Mandatory=$False)] $DeviceInfoId = 1) {
  Call-SoapService -Endpoint "http://$($Hostname):49000/upnp/control/deviceinfo" `
                   -ActionURI "urn:dslforum-org:service:DeviceInfo:$($DeviceInfoId)" `
                   -ActionCommand "GetSecurityPort" `
  | Unwrap-XmlContent
}

Function Get-AddonInfos([String] [Parameter(Mandatory=$False)] $Hostname = "fritz.box",
                        [Int]    [Parameter(Mandatory=$False)] $ConfigId = 1) {
  Call-SoapService -Endpoint "http://$($Hostname):49000/igdupnp/control/WANCommonIFC1" `
                   -ActionURI "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:$($ConfigId)" `
                   -ActionCommand "GetAddonInfos" `
  | Unwrap-XmlContent
}

Function Call-SoapService([Uri]    [Parameter(Mandatory=$False)] $Endpoint,
                          [Uri]    [Parameter(Mandatory=$False)] $ActionURI,
                          [String] [Parameter(Mandatory=$False)] $ActionCommand,
                          [String] $Username,
                          [String] $Password,
                          [String] $CommandKey,
                          [String] $CommandValue) {
        if ($Username) {
          $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
          $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        } else {
          $Credential = $Null
        }
        $Headers = @{'SOAPAction'="$($ActionURI)#$($ActionCommand)"};
        $SoapRequest = Create-SoapRequest -ActionURI $ActionURI `
                                          -ActionCommand $ActionCommand `
                                          -CommandKey $CommandKey `
                                          -CommandValue $CommandValue
        $RequestPayload = [System.Text.Encoding]::UTF8.GetBytes($SoapRequest.OuterXml)
        Write-Verbose "Request:"
        Write-Verbose $SoapRequest.OuterXml
        $Response = Invoke-WebRequest -URI $Endpoint `
                          -Method POST `
                          -ContentType 'text/xml;charset=utf-8' `
                          -Body $RequestPayload `
                          -Credential $Credential `
                          -Headers $Headers
        if ($Response) {
          Write-Verbose "Response:"
          Write-Verbose $Response.Content
          $Response
        }
}

Function Create-SoapRequest([Uri]    [Parameter(Mandatory=$False)] $ActionURI,
                            [String] [Parameter(Mandatory=$False)] $ActionCommand,
                            [String] $CommandKey,
                            [String] $CommandValue) {
        $Document = New-Object System.XML.XMLDocument
        [void] $Document.AppendChild($Document.CreateXmlDeclaration("1.0", "utf-8", $Null))
        $Envelope = $Document.AppendChild($Document.CreateElement("s", "Envelope", $Namespaces.env))
        [void] $Envelope.SetAttribute("encodingStyle", $Namespaces.env, "http://schemas.xmlsoap.org/soap/encoding/")
        $Body = $Envelope.AppendChild($Document.CreateElement("s", "Body", $Namespaces.env))
        $Command = $Body.AppendChild($Document.CreateElement("u", $ActionCommand, $ActionURI))
        if ($CommandKey) {
            $Command.AppendChild($Document.CreateElement($CommandKey)).InnerText = $CommandValue
        }
        $Document
}

Filter Unwrap-XmlContent {
  Param([Parameter(Mandatory=$True, ValueFromPipeline=$True)] [Microsoft.PowerShell.Commands.HtmlWebResponseObject] $Xml)
  $Xml | Select-Object -ExpandProperty Content `
       | Select-Xml -Namespace $Namespaces -XPath /env:Envelope/env:Body/* `
       | Select-Object -Expand Node `
       | Select-Object -ExpandProperty OuterXml
}

if (!$Args) {
  $ScriptFunctions = Get-ChildItem function: | Where-Object { $SystemFunctions -NotContains $_ } | Where-Object { $_.Name -Match $PublicCommands }
  Write-Host "Error: Missing command, choose one of:`n  $scriptFunctions"
} else {
  Invoke-Expression "$Args"
}
