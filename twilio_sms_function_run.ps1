using namespace System.Net

# HTTP Trigger
param($Request, $TriggerMetadata)

$pstTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Pacific Standard Time').ToString("yyyy-MM-dd HH:mm:ss.fff");
$funcName = "jc PowerShell Twilio HTTPTrigger1";

Write-Host("$funcName run.ps1 started at PST TIME: $pstTime.");

$toNumber = $Request.Query.toNumber;
$msgText = $Request.Query.msgText;

$phoneNumberLength = 10;
$TWILIO_NUMBER = $env:TWILIO_NUMBER;
$TWILIO_ACCOUNT_SID = $env:TWILIO_ACCOUNT_SID;
$TWILIO_AUTH_TOKEN = $env:TWILIO_AUTH_TOKEN;

if ((-not $TWILIO_NUMBER) -or (-not $TWILIO_ACCOUNT_SID) -or (-not $TWILIO_AUTH_TOKEN))
{ 
    $body = "Error: retrieving configuration.";
    Write-Host("$funcName $body");
    $status=[System.Net.HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = $body
    })
    return $null;
}

if ($msgText.Length -eq 0) 
{
    $body = "Error: message not provided.";
    Write-Host("$funcName $body");
    $status=[System.Net.HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = $body
    })
    return $null;
}

if ($toNumber.Length -eq $phoneNumberLength) 
{
    if ($toNumber -eq "defaultnum")
    {
        $toNumber = $env:jcPhone1;
    }
    else
    {
        $toNumber = "+1" + $toNumber;
    }
}
else 
{
    $body = "Error: Phone number `"" + $toNumber + "`" not correct length: (" + $phoneNumberLength + ").";
    Write-Host("$funcName $body");
    $status=[System.Net.HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = $body
    })
    return $null;
}

$url = "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json";
$params = @{ To = $toNumber; From = $TWILIO_NUMBER; Body = $msgText };

# Create a credential object for HTTP basic auth
$p = $TWILIO_AUTH_TOKEN | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($TWILIO_ACCOUNT_SID, $p)

try
{
    # Make API request, selecting JSON properties from response
    Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing  |
    ConvertFrom-Json | Select-Object sid, body;
}
catch
{
    $body = "Error: occurred with web request to send message.";
    Write-Host("$funcName $body");
    Write-Error  $_

    $status=[System.Net.HttpStatusCode]::BadRequest
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = $body
    })
    return $null;

}

$body = "Message sent - UTC: " + [datetime]::Now.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
Write-Host($body);
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})


$pstTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Pacific Standard Time').ToString("yyyy-MM-dd HH:mm:ss.fff");
Write-Host("$funcName run.ps1 completed at PST TIME: $pstTime.");

