# Check script pre-req
$ModCheck = Get-Module -ListAvailable -Name Anybox
if ($ModCheck -ne $null ) {
    Write-Host "Required Modules exist"
} else {
    Install-Module -Name Anybox
}

# Pull in Twilio account info, previously set as environment variables
$sid = "ACc47983f8612c5f7e3b7767f240e80516"
$token = "a3033ce358069a7e0d3035acee222668"
$number = "+13014789496"

Do {
    $Prompt = Show-anybox -Buttons "Submit" -Prompt @(
        New-AnyBoxPrompt -InputType Text -Name 'Number' -Message 'Recipient Phone Number' -ValidateNotEmpty
        New-AnyBoxPrompt -InputType Text -Name 'Text' -Message 'SMS Message' -ValidateNotEmpty
    )
    If ( $Prompt.Number -notlike "+1*" ) {
        Show-Anybox -Buttons "Ok" -Message 'Recipient Phone Number must start with "+1"'
        $Prompt = @()
        }
} while (
    $Prompt.Number -notlike "+1*"
)
# Twilio API endpoint and POST params
$url = "https://api.twilio.com/2010-04-01/Accounts/$sid/Messages.json"
$params = @{ To = $Prompt.Number; From = $number; Body = $Prompt.Text }

# Create a credential object for HTTP basic auth
$p = $token | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($sid, $p)

# Make API request, selecting JSON properties from response
Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing |
ConvertFrom-Json | Select sid, body