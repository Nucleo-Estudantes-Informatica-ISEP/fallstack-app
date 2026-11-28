# Windows entry point for setup.sh. Finds Git Bash and runs the shell script.
# Usage: pwsh scripts/agents/setup.ps1 [--no-guide] <agent>...
$ErrorActionPreference = 'Stop'

# Prefer the bash that ships with Git for Windows. The bash.exe in
# C:\Windows\System32 starts WSL instead and cannot read Windows paths.
$bash = $null
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
  $candidate = Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe'
  if (Test-Path $candidate) { $bash = $candidate }
}
if (-not $bash) {
  $candidate = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
  if (Test-Path $candidate) { $bash = $candidate }
}
if (-not $bash) {
  Write-Error 'Git Bash not found. Install Git for Windows, or run scripts/agents/setup.sh from WSL.'
}

$script = (Join-Path $PSScriptRoot 'setup.sh') -replace '\\', '/'
& $bash $script @args
exit $LASTEXITCODE
