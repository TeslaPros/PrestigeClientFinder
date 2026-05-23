[CmdletBinding()]
param(
    [switch]$SkipRuntimeScan,
    [switch]$Quiet
)

Set-StrictMode -Version 3
$ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "TeslaPro's Prestige Finder"

$script:Results = New-Object System.Collections.Generic.List[object]

$script:Config = @{
    Name = "TeslaPro's Prestige Finder"
    Version = "3.0.0"
    Creator = "TeslaPro"

    PrestigeFileNameNeedles = @(
        "prestige",
        "prestigeclient",
        "prestige injector",
        "prestigeinjector",
        "prestige-injector",
        "prestige_injector",
        ".psaclient"
    )

    PrestigeExactStrings = @(
        "dev/zprestige/prestige",
        "dev/zprestige/prestige/client/Prestige",
        "dev.zprestige.prestige",
        "assets/prestige/sounds/pop2.wav",
        "assets/prestige/sounds/pop3.wav",
        "assets/prestige/font/inter/json",
        "assets/prestige/icons/categories/mace",
        "assets/prestige/icons/hud/potion",
        "assets/prestige/icons/hud/latency",
        "assets/prestige/icons/hud/clock",
        "prestigeclient.vip",
        ".prestigeclient.vip0",
        "prestige_4.properties",
        ".psaclient",
        "prestige injector",
        "prestigeinjector",
        "prestige-injector",
        "prestige_injector"
    )

    RuntimeInjectionPatterns = @(
        [pscustomobject]@{ Label = "Java agent injection"; Pattern = "(?i)-javaagent:"; Risk = 5 },
        [pscustomobject]@{ Label = "Native agent injection"; Pattern = "(?i)-agentpath:"; Risk = 5 },
        [pscustomobject]@{ Label = "Agent library injection"; Pattern = "(?i)-agentlib:"; Risk = 5 },
        [pscustomobject]@{ Label = "Boot classpath injection"; Pattern = "(?i)-Xbootclasspath"; Risk = 5 },
        [pscustomobject]@{ Label = "Fabric addMods injection"; Pattern = "(?i)-Dfabric\.addMods="; Risk = 5 },
        [pscustomobject]@{ Label = "Fabric loadMods injection"; Pattern = "(?i)-Dfabric\.loadMods="; Risk = 5 },
        [pscustomobject]@{ Label = "Fabric custom mod list"; Pattern = "(?i)-Dfabric\.customModList="; Risk = 4 },
        [pscustomobject]@{ Label = "Forge addMods injection"; Pattern = "(?i)-Dforge\.addMods="; Risk = 5 },
        [pscustomobject]@{ Label = "Forge coremod load"; Pattern = "(?i)-Dfml\.coreMods\.load="; Risk = 5 },
        [pscustomobject]@{ Label = "System classloader override"; Pattern = "(?i)-Djava\.system\.class\.loader="; Risk = 5 }
    )

    ScanRoots = @(
        "$env:APPDATA\.minecraft",
        "$env:APPDATA\.lunarclient",
        "$env:APPDATA\.feather",
        "$env:APPDATA\Feather Launcher",
        "$env:APPDATA\.badlion",
        "$env:APPDATA\Badlion Client",
        "$env:APPDATA\PrismLauncher",
        "$env:APPDATA\MultiMC",
        "$env:APPDATA\ModrinthApp",
        "$env:TEMP",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop"
    )
}

function Banner {
    if ($Quiet) { return }

    Clear-Host
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  TESLAPRO'S PRESTIGE FINDER v$($script:Config.Version)" -ForegroundColor Cyan
    Write-Host "  Active PID Scan • Prestige File Names • JAR Internal String Scan" -ForegroundColor White
    Write-Host "  Built by $($script:Config.Creator)" -ForegroundColor DarkGray
    Write-Host "══════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
}

function Section($Title) {
    if ($Quiet) { return }
    Write-Host ""
    Write-Host "[ $Title ]" -ForegroundColor Cyan
}

function Info($Text) {
    if ($Quiet) { return }
    Write-Host "  $Text" -ForegroundColor Gray
}

function Warn($Text) {
    if ($Quiet) { return }
    Write-Host "  [WARN] $Text" -ForegroundColor Yellow
}

function Found($Type, $Match, $Location, $Risk) {
    $script:Results.Add([pscustomobject]@{
        Type = $Type
        Match = $Match
        Location = $Location
        Risk = $Risk
    })

    if ($Quiet) { return }

    Write-Host "  [FOUND] " -NoNewline -ForegroundColor Red
    Write-Host "$Type " -NoNewline -ForegroundColor Yellow
    Write-Host "-> " -NoNewline -ForegroundColor DarkGray
    Write-Host $Match -ForegroundColor Magenta
    Write-Host "          $Location" -ForegroundColor Gray
}

function Is-MinecraftRuntimeProcess {
    param($Proc)

    $name = [string]$Proc.Name
    $cmd = [string]$Proc.CommandLine

    return (
        $name -match "java|javaw|minecraft|lunar|badlion|feather|prismlauncher|multimc|modrinth" -or
        $cmd -match "\.minecraft|fabric|forge|lunarclient|feather|badlion|minecraft"
    )
}

function RuntimeScan {
    if ($SkipRuntimeScan) { return }

    Section "ACTIVE MINECRAFT PID / RUNTIME SCAN"

    $procs = @(Get-CimInstance Win32_Process | Where-Object { Is-MinecraftRuntimeProcess $_ })

    if ($procs.Count -eq 0) {
        Warn "No active Minecraft Java PID found."
        return
    }

    foreach ($proc in $procs) {
        $cmd = [string]$proc.CommandLine

        Info "PID $($proc.ProcessId) | $($proc.Name)"

        foreach ($s in $script:Config.PrestigeExactStrings) {
            if ($cmd.IndexOf($s, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                Found "Runtime Prestige String" $s "PID $($proc.ProcessId)" 5
            }
        }

        foreach ($rule in $script:Config.RuntimeInjectionPatterns) {
            if ($cmd -match $rule.Pattern) {
                Found "Runtime Injection" $rule.Label "PID $($proc.ProcessId)" $rule.Risk
            }
        }
    }
}

function PrestigeFileNameScan {
    Section "PRESTIGE FILE / FOLDER NAME SCAN"

    foreach ($root in $script:Config.ScanRoots) {
        if (-not (Test-Path $root)) { continue }

        Info "Checking $root"

        Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $item = $_
            $name = $item.Name.ToLowerInvariant()
            $full = $item.FullName

            foreach ($needle in $script:Config.PrestigeFileNameNeedles) {
                if ($name.Contains($needle.ToLowerInvariant())) {
                    Found "Prestige Name" $needle $full 3
                }
            }
        }
    }
}

function PrestigeJarScan {
    Section "PRESTIGE JAR INTERNAL STRING SCAN"

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    foreach ($root in $script:Config.ScanRoots) {
        if (-not (Test-Path $root)) { continue }

        Get-ChildItem -LiteralPath $root -Recurse -Force -File -Filter "*.jar" -ErrorAction SilentlyContinue |
        ForEach-Object {
            $jar = $_.FullName

            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($jar)
                $entries = ($zip.Entries | Select-Object -ExpandProperty FullName) -join "`n"

                foreach ($s in $script:Config.PrestigeExactStrings) {
                    if ($entries.IndexOf($s, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                        Found "JAR Prestige String" $s $jar 5
                    }
                }

                $zip.Dispose()
            } catch {}
        }
    }
}

function Summary {
    Section "SCAN SUMMARY"

    if ($script:Results.Count -eq 0) {
        Write-Host "  Status: CLEAN - No Prestige artifacts found." -ForegroundColor Green
    } else {
        $risk = ($script:Results | Measure-Object Risk -Sum).Sum

        Write-Host "  Status: REVIEW REQUIRED" -ForegroundColor Red
        Write-Host "  Matches: $($script:Results.Count)" -ForegroundColor Yellow
        Write-Host "  Risk Score: $risk" -ForegroundColor Yellow
        Write-Host ""

        $script:Results |
            Sort-Object Risk -Descending |
            Format-Table Type, Match, Risk, Location -AutoSize
    }

    $report = "$env:USERPROFILE\Desktop\TeslaPros-Prestige-Finder-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $script:Results | Out-File -FilePath $report -Encoding UTF8

    Write-Host ""
    Write-Host "  Report saved: $report" -ForegroundColor Green
}

Banner
RuntimeScan
PrestigeFileNameScan
PrestigeJarScan
Summary

Write-Host ""
Read-Host "Press ENTER to exit"