$metadata = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
$zone = $metadata.compute.zone

Add-WindowsFeature Web-Server

$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Application Availability</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background: linear-gradient(135deg, #0093E9 0%, #80D0C7 100%);
        }

        .container {
            background: rgba(255, 255, 255, 0.95);
            padding: 2rem;
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
        }

        h1 {
            color: #2c3e50;
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }

        .info-box {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 1.5rem;
            margin: 1rem 0;
            border-left: 5px solid #0093E9;
        }

        .hostname {
            color: #2980b9;
            font-size: 1.8rem;
            font-weight: bold;
            margin: 0.5rem 0;
        }

        .zone {
            color: #27ae60;
            font-size: 3.5rem;
            font-weight: bold;
        }

        .timestamp {
            color: #7f8c8d;
            font-size: 0.9rem;
            margin-top: 2rem;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        .pulse {
            animation: pulse 2s infinite;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Application Availability</h1>
        <div class="info-box">
            <div>Running on host:</div>
            <div class="hostname pulse">$($env:computername)</div>
            <div>Deployed in:</div>
            <div class="zone">Zone #${zone}</div>
        </div>
        <div class="timestamp">
            Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value $htmlContent