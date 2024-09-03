$metadata=Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
$zone=$metadata.compute.zone
Add-WindowsFeature Web-Server
Set-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value "Hello from host $($env:computername) deployed in zone #${zone} !"