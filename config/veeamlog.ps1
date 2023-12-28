function Get-Result {
  $LogPath = 'C:\ProgramData\Veeam\Endpoint'

  if (-not $LogPath) {
    Write-Output '[{"job_name": "", "job_status": "FAILED", "description": "Job directory not found"}]'
    exit
  }

  $LogFile = Get-ChildItem -Filter Job.*.Backup.log -Recurse -Path $LogPath | Sort-Object LastWriteTime | Select-Object -First 1

  if (-not $LogFile.FullName) {
    Write-Output '[{"job_name": "", "job_status": "FAILED", "description": "Job file not found"}]'
    exit
  }

  $LogStdout = Get-Content -Path $LogFile.FullName -Tail 50
  $JobName = ($LogFile.Name -split "\.")[1]

  if ($LogStdout -match "status: 'Success'") {
    Write-Output (-join('[{"job_name": "', $JobName, '", "job_status": "SUCCESS", "description": "Job ended with success"}]'))
  }
  elseif ($LogStdout -match "status: 'Warning'") {
    Write-Output (-join('[{"job_name": "', $JobName, '", "job_status": "WARNING", "description": "Job ended with warning"}]'))
  }
  else {
    Write-Output (-join('[{"job_name": "', $JobName, '", "job_status": "FAILED", "description": "Job ended with fail"}]'))
  }
}

$JobResult = Get-Result

if (-not $args) {
  exit
}

if ($args[0] -eq 'json') {
  Write-Output $JobResult
}
elseif ($args[0] -eq 'num') {
  if ($JobResult -match 'SUCCESS') {
    Write-Output 2
  }
  elseif ($JobResult -match 'WARNING') {
    Write-Output 1
  }
  else {
    Write-Output 0
  }
}