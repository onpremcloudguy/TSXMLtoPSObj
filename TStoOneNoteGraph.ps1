
#go to https://apps.dev.microsoft.com and create a new application to get the Client ID and Secrect with the required level of access.
$clientid = ""
$clientSecret = ""
$useremail = ""
$resource = "https://graph.microsoft.com"
$prompt = "login"
$redirectUri = "http://localhost"

function get-GraphAPIToken
{
  param
  (
    [String]
    [Parameter(Mandatory)]
    $clientSecret,
    [String]
    [Parameter(Mandatory)]
    $clientid,
    [string]
    [Parameter(Mandatory)]
    $Redirecturi,
    [string]
    [Parameter(Mandatory)]
    $resource,
    [string]
    [Parameter(Mandatory)]
    $useremail,
    [string]
    [ValidateSet('admin_consent','login','consent')]
    $PromptType 
  )

  Add-Type -AssemblyName system.web
  #encoded Variables for the oauth string. 
  $clientIDEncoded = [Web.HttpUtility]::UrlEncode($clientid)
  $clientSecretEncoded = [Web.HttpUtility]::UrlEncode($clientSecret)
  $redirectUriEncoded =  [Web.HttpUtility]::UrlEncode($redirectUri)
  $resourceEncoded = [Web.HttpUtility]::UrlEncode($resource)

  # Get oauth2 Code
  $url = ('https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&redirect_uri={0}&client_id={1}&resource={2}&prompt={3}&login_hint={4}' -f $redirectUriEncoded, $clientIDEncoded, $resourceEncoded, $prompttype, $useremail)

  # Pops a window to Authenticate to Microsoft Online.
  $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=420;Height=600}
  $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=$url}
  $DocComp  = {$script:uri = $web.Url.AbsoluteUri; if ($script:uri -match "error=[^&]*|code=[^&]*") {$form.Close()}}
  $web.ScriptErrorsSuppressed = $true
  $web.Add_DocumentCompleted($DocComp)
  $form.Controls.Add($web)
  $form.Add_Shown({$form.Activate()})
  $null = $form.ShowDialog()
  $authCode = ([Web.HttpUtility]::ParseQueryString($web.Url.Query))["code"]

  # Convert the oAuth2 code into a Token.
  $body = ('grant_type=authorization_code&redirect_uri={0}&client_id={1}&client_secret={2}&code={3}&resource={4}' -f $redirectUri, $clientId, $clientSecretEncoded, $authCode, $resource)
  (Invoke-RestMethod -Uri https://login.microsoftonline.com/common/oauth2/token -Method Post -ContentType 'application/x-www-form-urlencoded' -Body $body -ErrorAction STOP).access_token
}
#import-module azureadpreview
$token = get-GraphAPIToken -clientSecret $clientSecret -clientid $clientid -Redirecturi $redirectURI -resource $resource -useremail $useremail -prompttype $prompt

$newnotebook = Invoke-RestMethod -Headers @{Authorization = "Bearer $token"} -uri "https://graph.microsoft.com/beta/me/onenote/notebooks" -Method POST -body (@{"displayName"= "SCCMDocs"} | convertto-json) -ContentType "application/json"

$newOneNoteSection = Invoke-RestMethod -headers @{Authorization = "Bearer $token"} -uri "https://graph.microsoft.com/beta/me/onenote/notebooks/$($newnotebook.id)/sections" -Method POST -body (@{"displayName"= "TS"} | convertto-json) -ContentType "application/json"

$grpnames =  $tsgroups.name -join "</p> <p>"
$stepnames = $tsgroups.steps.name -join "</p> <p>"
$htmlcontent = @"
<!DOCTYPE html>
<html>
  <head>
    <title>Task Sequence name: $($PSObjOSDSettings.name)</title>
    <meta name="created" content="2015-07-22T09:00:00-08:00" />
  </head>
  <body>
    <p>There are $($tsgroups.count) Groups which make up the Task Sequence they are named:</p>
    <p><b>$grpnames</b></p>
    <p>There are $($tsgroups.steps.count) Steps in the Taask Sequence, they are names:</p>
    <p><b><i>$stepnames</i></b></p>
  </body>
</html>
"@

$newOneNotePage = Invoke-RestMethod -headers @{Authorization = "Bearer $token"} -uri "https://graph.microsoft.com/beta/me/onenote/sections/$($newOneNoteSection.id)/pages" -Method POST -body $htmlcontent -ContentType "text/html"