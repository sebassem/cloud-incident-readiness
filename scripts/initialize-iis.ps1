$metadata = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
$zone = $metadata.compute.zone
Add-WindowsFeature Web-Server

$css = @"
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            color: #333;
            text-align: center;
            padding-top: 50px;
        }
        h1 {
            font-size: 2em;
            color: #0078D7;
        }
        p {
            font-size: 1.2em;
        }
    </style>
"@

$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure VM</title>
    $css
</head>
<body>
    <h1>Hello from host $($env:computername)!</h1>
    <p>Deployed in Zone #${zone}</p>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value $htmlContent