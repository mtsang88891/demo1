# Clone-ConclusionHQ.ps1
# Requires: git installed. Optional: set $env:GITHUB_TOKEN for higher API rate limits.
$org  = "ConclusionHQ"
$dest = "C:\DEVOPS\TFPublicModules\ConclusionHQ"
$perPage = 100
$token = $env:GITHUB_TOKEN   # optional

# Create destination
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Set-Location $dest

# Build headers (include token only if present)
$headers = @{ "User-Agent" = "PowerShell" }
if ($token) { $headers.Authorization = "token $token" }

# Start with first page
$uri = "https://api.github.com/orgs/$org/repos?per_page=$perPage&page=1"

while ($uri) {
    try {
        $resp = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get -UseBasicParsing
    } catch {
        Write-Error "Failed to fetch $uri : $_"
        break
    }

    $repos = $resp.Content | ConvertFrom-Json
    foreach ($r in $repos) {
        $name = $r.name
        $cloneUrl = "https://github.com/$org/$name.git"
        $target = Join-Path $dest $name
        if (Test-Path $target) {
            Write-Host "Skipping existing: $name"
            continue
        }
        Write-Host "Cloning $name ..."
        git clone $cloneUrl
    }

    # Parse Link header for next page
    $link = $resp.Headers["Link"]
    if ($link) {
        $next = ($link -split ",") | ForEach-Object {
            if ($_ -match 'rel="next"') { ($_ -split ";")[0].Trim() -replace '<|>' }
        } | Where-Object { $_ } | Select-Object -First 1
        $uri = $next
    } else {
        $uri = $null
    }
}

Write-Host "All done."