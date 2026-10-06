# LeadSonar bootstrap - the public first step of the install on Windows.
#
#   irm https://raw.githubusercontent.com/InfiniteSolutionCZ/bootstrap/main/leadsonar/install.ps1 | iex
#
# LeadSonar lives in a private repository. This script asks for the GitHub token the
# user was given, downloads the real install script from that repository with it, and
# runs it. The install script hands the token to the Git credential helper for the
# LeadSonar repository only (credential.useHttpPath), so updates work later without a
# sign-in and no other repository or push sees the token.
#
# The token is read without echo and never written to a file, the command line or the
# PowerShell history; it reaches the install script through an environment variable of
# its process only. Everything runs in a script block, so `| iex` leaves no variables
# behind in the user's session, and no `exit` closes the user's window.

& {
    $ErrorActionPreference = "Stop"
    # Invoke-WebRequest is many times slower with its progress bar in Windows PowerShell
    $ProgressPreference = "SilentlyContinue"
    # Windows PowerShell 5.1 on an old .NET may not offer TLS 1.2 by default
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $repository = "InfiniteSolutionCZ/leadsonar"
    $contact = "Zdenek"
    $script = Join-Path $env:TEMP "leadsonar-install.ps1"

    Write-Host ""
    Write-Host "==> LeadSonar install" -ForegroundColor Cyan
    Write-Host "    LeadSonar is in a private GitHub repository. Paste the GitHub token you were"
    Write-Host "    given (right click or Ctrl+V) and press Enter - nothing is shown while you paste."
    Write-Host "    You do not have a token? Ask $contact."
    $secure = Read-Host "GitHub token" -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $token = ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)).Trim() }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    if (-not $token) {
        Write-Host "No token given - nothing was installed." -ForegroundColor Red
        return
    }

    $headers = @{
        Authorization = "Bearer $token"
        Accept = "application/vnd.github.raw"
        "User-Agent" = "leadsonar-bootstrap"
    }
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 -Headers $headers -OutFile $script `
            -Uri "https://api.github.com/repos/$repository/contents/scripts/install.ps1?ref=main"
    }
    catch {
        $status = $null
        try { $status = [int]$_.Exception.Response.StatusCode } catch { }
        if ($status -in 401, 403, 404) {
            Write-Host ("GitHub did not accept the token - it is mistyped, incomplete or has expired. " +
                "Ask $contact for a new one. Nothing was installed.") -ForegroundColor Red
        }
        else {
            Write-Host "GitHub could not be reached: $($_.Exception.Message). Nothing was installed." -ForegroundColor Red
        }
        return
    }
    Write-Host "    The token works - starting the LeadSonar install script" -ForegroundColor Green

    # Only the install process inherits it; the variable is gone when this block ends
    $env:LEADSONAR_GITHUB_TOKEN = $token
    try {
        & powershell.exe -NoProfile -ExecutionPolicy ByPass -File $script
    }
    finally {
        Remove-Item Env:LEADSONAR_GITHUB_TOKEN -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script -ErrorAction SilentlyContinue
    }
}
