# tr064-client

## Description
A simple TR-064 client written in PowerShell

Motivation for this client was the requirement to enable and disable the guest
WiFi of an AVM Fritz!Box from the Windows platform.

The script has no dependencies and is prepared to be extended for further commands.

## Examples
- Enable guest WiFi:
  `PowerShell -File tr064-client.ps1 Switch-WLAN -Enable true  -Username username -Password password`
- Disable guest WiFi:
  `PowerShell -File tr064-client.ps1 Switch-WLAN -Enable false -Username username -Password password`
- Enable WiFi with ID 2 on 192.168.1.100:
  `PowerShell -File tr064-client.ps1 Switch-WLAN -Enable true  -Username username -Password password -WlanId 2 -Hostname 192.168.1.100`
- Get call list:
  `PowerShell -File tr064-client.ps1 Get-CallList -Username username -Password password`
- Get security port:
  `PowerShell -File tr064-client.ps1 Get-SecurityPort`
- Dump XML request and response:
  `PowerShell -File tr064-client.ps1 Get-SecurityPort -Verbose`

## References
- [AVM TR-064 resources](https://avm.de/service/schnittstellen/)
- [Gäste WLAN Ein / Ausschalten](https://www.schlaue-huette.de/apis-co/fritz-tr064/gaeste-wlan-ein-ausschalten/)
