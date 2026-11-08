param(
    [string]$Platform = 'C:\Program Files (x86)\1cv8t\8.5.1.1150\bin\1cv8t.exe',
    [string]$BasePath = (Join-Path $PSScriptRoot '..\..\bases\mini-sklad-week3-autocheck'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\..\validation\week3-autocheck')
)
$ErrorActionPreference = 'Stop'
$SourcePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BasePath = [IO.Path]::GetFullPath($BasePath)
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
if (-not (Test-Path -LiteralPath $Platform)) { throw "Платформа не найдена: $Platform" }
if (Test-Path -LiteralPath (Join-Path $BasePath '1Cv8.1CD')) {
    throw 'Для проверки укажите новую пустую папку BasePath. Рабочая база не изменялась.'
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
function Invoke-Platform([string[]]$Arguments, [string]$LogName) {
    $logPath = Join-Path $OutputPath $LogName
    $allArguments = $Arguments + @('/DisableStartupMessages','/DisableStartupDialogs','/Out',('"'+$logPath+'"'))
    $process = Start-Process -FilePath $Platform -ArgumentList $allArguments -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Ошибка 1С. Журнал: $logPath" }
}
Invoke-Platform @('CREATEINFOBASE',('File="'+$BasePath+'";')) 'create.log'
Invoke-Platform @('DESIGNER','/F',('"'+$BasePath+'"'),'/LoadConfigFromFiles',('"'+$SourcePath+'"')) 'load.log'
Invoke-Platform @('DESIGNER','/F',('"'+$BasePath+'"'),'/UpdateDBCfg') 'update.log'
Invoke-Platform @('DESIGNER','/F',('"'+$BasePath+'"'),'/CheckConfig','-ThinClient','-Server') 'check.log'
$result = Join-Path $OutputPath 'results.txt'
Invoke-Platform @('ENTERPRISE','/F',('"'+$BasePath+'"'),('/C"Week3Check='+$result+'"')) 'runtime.log'
if (-not (Test-Path -LiteralPath $result)) { throw '1С не создала протокол проверки.' }
$text = Get-Content -LiteralPath $result -Raw -Encoding UTF8
Write-Output $text
if ($text -notmatch 'SUCCESS:') { throw 'Контрольные сценарии не пройдены.' }
