function Get-Result {
  $LogPath = 'C:\ProgramData\Veeam\Endpoint'
  $JobDir = Get-ChildItem -Directory -Path $LogPath | Sort-Object LastWriteTime | Select-Object -First 1
  $JobDirPath = $JobDir.FullName
  $JobDirName = $JobDir.Name

  if (-not $JobDirPath) {
    Write-Output '[{"job_name": "", "job_status": "FAILED", "description": "Job directory not found"}]'
    exit
  }

  $LogFileName = 'Agent.' + $JobDirName + '.Index.log'

  $LogFilePath = Join-Path $JobDirPath $LogFileName

  $LogStdout = Get-Content -Path $LogFilePath -Tail 20

  if ($LogStdout -match 'The agent session has finished successfully.') {
    Write-Output (-join('[{"job_name": "', $JobDirName, '", "job_status": "SUCCESS", "description": "Job ended with success"}]'))
  }
  else {
    Write-Output (-join('[{"job_name": "', $JobDirName, '", "job_status": "FAILED", "description": "Job ended with fail"}]'))
    Write-Output 
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
    Write-Output 1
  }
  else {
    Write-Output 0
  }
}