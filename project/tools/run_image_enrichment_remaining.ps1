param(
  [int]$Start = 524,
  [int]$End = 2994,
  [int]$BatchSize = 100,
  [int]$MaxImages = 2,
  [int]$DelayMs = 700,
  [switch]$NoOverwrite,
  [switch]$ContinueOnItemErrors
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$logDir = Join-Path $projectRoot "dataset\image_enrichment_logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$summaryLog = Join-Path $logDir "remaining_$timestamp.log"
$overwriteArg = if ($NoOverwrite) { "false" } else { "true" }

Set-Location $projectRoot

function Write-RunLog {
  param([string]$Message)
  $line = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $Message"
  Write-Host $line
  Add-Content -Path $summaryLog -Value $line -Encoding UTF8
}

Write-RunLog "Starting remaining attraction image enrichment."
Write-RunLog "Project: $projectRoot"
Write-RunLog "Range: $Start-$End batchSize=$BatchSize maxImages=$MaxImages delayMs=$DelayMs overwrite=$overwriteArg continueOnItemErrors=$ContinueOnItemErrors"
Write-RunLog "Reminder: temporarily enable Firestore attractions images/updatedAt update rule before real batches, then lock rules back after completion."

for ($start = $Start; $start -le $End; $start += $BatchSize) {
  $limit = [Math]::Min($BatchSize, $End - $start + 1)
  $batchLog = Join-Path $logDir ("batch_{0:D4}_{1:D4}_$timestamp.log" -f $start, ($start + $limit - 1))

  Write-RunLog "Batch start=$start limit=$limit log=$batchLog"

  $nodeArgs = @(
    "tools\enrich_attraction_images_to_storage.mjs",
    "--start=$start",
    "--limit=$limit",
    "--max-images=$MaxImages",
    "--delay-ms=$DelayMs",
    "--overwrite=$overwriteArg"
  )

  $oldNativePreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = & node $nodeArgs 2>&1
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $oldNativePreference

  $output | Tee-Object -FilePath $batchLog | Out-Null

  if ($exitCode -ne 0) {
    Write-RunLog "Batch failed start=$start exit=$exitCode"
    $billingDenied = ($output | Select-String -Pattern 'REQUEST_DENIED|enable Billing').Count -gt 0
    if ($billingDenied) {
      Write-RunLog "Stopped because Google Places API requires an active Billing account. Fix Billing, then rerun: powershell -ExecutionPolicy Bypass -File tools\run_image_enrichment_remaining.ps1 -Start $start"
    }
    exit $exitCode
  }

  $okCount = ($output | Select-String -Pattern '^\[ok\]').Count
  $noneCount = ($output | Select-String -Pattern '^\[none\]').Count
  $errorCount = ($output | Select-String -Pattern '^\[error\]').Count
  Write-RunLog "Batch complete start=$start ok=$okCount none=$noneCount errors=$errorCount"

  if ($errorCount -gt 0) {
    $billingDenied = ($output | Select-String -Pattern 'REQUEST_DENIED|enable Billing').Count -gt 0
    if ($billingDenied) {
      Write-RunLog "Stopped because Google Places API requires an active Billing account. Fix Billing, then rerun: powershell -ExecutionPolicy Bypass -File tools\run_image_enrichment_remaining.ps1 -Start $start"
      exit 1
    } elseif ($ContinueOnItemErrors) {
      Write-RunLog "Continuing despite item errors. Review $batchLog later."
    } else {
      Write-RunLog "Stopped because this batch contains item errors. Review $batchLog, then rerun from start=$start."
      exit 1
    }
  }
}

Write-RunLog "All remaining batches completed."
