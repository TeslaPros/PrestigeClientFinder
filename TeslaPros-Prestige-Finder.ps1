[CmdletBinding()]
param(
    [string]$Path,
    [switch]$SkipRuntimeScan,
    [switch]$Quiet
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "TeslaPro's Prestige Finder"

$script:Config = @{
    Name = "TeslaPro's Prestige Finder"
    Version = "2.0.0"
    Creator = "TeslaPro"

    PrestigeStrings = @(
        "prestige",
        "Prestige Client",
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
        "*.prestigeclient.vip0",
        "prestigeclient.vip",
        "prestige_4.properties",
        ".prestigeclient.vip0",
        "assets/minecraft/optifine/cit/profile/prestige/",
        ".psaclient"
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
        [pscustomobject]@{ Label = "System classloader override"; Pattern = "(?i)-Djava\.system\.class\.loader="; Risk = 5 },
        [pscustomobject]@{ Label = "Classpath override"; Pattern = "(?i)-Djava\.class\.path="; Risk = 3 }
    )

    LauncherPaths = @(
        "$env:APPDATA\.minecraft",
        "$env:APPDATA\.minecraft\mods",
        "$env:APPDATA\.minecraft\versions",
        "$env:APPDATA\.minecraft\libraries",
        "$env:APPDATA\.minecraft\logs",
        "$env:APPDATA\.lunarclient",
        "$env:USERPROFILE\.lunarclient",
        "$env:APPDATA\.feather",
        "$env:APPDATA\Feather Launcher",
        "$env:APPDATA\.badlion",
        "$env:APPDATA\Badlion Client",
        "$env:APPDATA\PrismLauncher",
        "$env:APPDATA\MultiMC",
        "$env:APPDATA\ModrinthApp",
        "$env:TEMP",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents"
    )
}

$script:Results = New-Object System.Collections.Generic.List[object]

function Rule { if (-not $Quiet) { Write-Host ("═" * 74) -ForegroundColor DarkCyan } }

function Banner {
    if ($Quiet) { return }
    Clear-Host
    Write-Host ""
    Rule
    Write-Host "   TESLAPRO'S PRESTIGE FINDER v$($script:Config.Version)" -ForegroundColor Cyan
    Write-Host "   Runtime PID • JAR entries • Prestige strings • Launcher scan" -ForegroundColor White
    Write-Host "   Built by $($script:Config.Creator)" -ForegroundColor DarkGray
    Rule
    Write-Host ""
}

function Section($Title) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "[ $Title ]" -ForegroundColor Cyan
    }
}

function Add-Result($Type, $Match, $Location, $Risk) {
    $script:Results.Add([pscustomobject]@{
        Type = $Type
        Match = $Match
        Location = $Location
        Risk = $Risk
    })

    if (-not $Quiet) {
        Write-Host "  [FOUND] " -NoNewline -ForegroundColor Red
        Write-Host "$Type " -NoNewline -ForegroundColor Yellow
        Write-Host "=> $Match" -ForegroundColor Magenta
        Write-Host "          $Location" -ForegroundColor Gray
    }
}

function Get-CommandTokens($CommandLine) {
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return @() }

    $tokens = New-Object System.Collections.Generic.List[object]
    $matches = [regex]::Matches($CommandLine, '"[^"]*"|''[^'']*''|\S+')

    foreach ($m in $matches) {
        $tokens.Add([pscustomobject]@{
            Text = $m.Value
            Start = $m.Index
            End = $m.Index + $m.Length - 1
        })
    }

    return @($tokens.ToArray())
}

function Get-TokenAtPosition($Tokens, $Position) {
    foreach ($t in $Tokens) {
        if ($Position -ge $t.Start -and $Position -le $t.End) {
            return $t
        }
    }
    return $null
}

function Normalize-JarPath($Candidate) {
    if ([string]::IsNullOrWhiteSpace($Candidate)) { return "" }

    $n = $Candidate.Trim().Trim('"').Trim("'")

    if ($n -match '^[^=]+=(.+)$') { $n = $matches[1].Trim() }
    if ($n -match '^(?i)-javaagent:(.+)$') { $n = $matches[1].Trim() }
    if ($n -match '^(?i)-agentpath:(.+)$') { $n = $matches[1].Trim() }

    $n = [Environment]::ExpandEnvironmentVariables($n)
    $n = $n -replace '[?#].*$', ''
    $n = $n.Trim().Trim('"').Trim("'").TrimEnd(",", ";")

    if ($n -notmatch '(?i)\.(jar|zip)$') { return "" }
    return $n
}

function Get-ReferencedJarPaths($Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    $candidates = New-Object System.Collections.Generic.List[string]
    $patterns = @(
        '(?i)"((?:[A-Z]:\\|\\\\)[^"]+\.(?:jar|zip))"',
        "(?i)'((?:[A-Z]:\\|\\\\)[^']+\.(?:jar|zip))'",
        '(?i)((?:[A-Z]:\\|\\\\|\.{1,2}[\\/])[^"''\s,;]+\.(?:jar|zip))'
    )

    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($Text, $p)) {
            $candidates.Add($m.Groups[1].Value)
        }
    }

    foreach ($part in $Text -split "[,;]") {
        if ($part -match '(?i)\.(jar|zip)') {
            $candidates.Add($part)
        }
    }

    $out = foreach ($c in ($candidates | Select-Object -Unique)) {
        $n = Normalize-JarPath $c
        if ($n) { $n }
    }

    return @($out | Select-Object -Unique)
}

function Get-JavaProcesses {
    Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -match "java|javaw|minecraft|lunar|badlion|feather|prismlauncher|multimc|modrinth"
    }
}

function Scan-Runtime {
    if ($SkipRuntimeScan) { return }

    Section "Active Minecraft PID / Runtime Scan"

    $procs = @(Get-JavaProcesses)

    if ($procs.Count -eq 0) {
        Write-Host "  No active Java/Minecraft processes found." -ForegroundColor DarkGray
        return
    }

    foreach ($proc in $procs) {
        $cmd = [string]$proc.CommandLine
        $tokens = @(Get-CommandTokens $cmd)

        Write-Host "  PID $($proc.ProcessId) | $($proc.Name)" -ForegroundColor Gray

        foreach ($s in $script:Config.PrestigeStrings) {
            if ($cmd -like "*$s*") {
                Add-Result "Runtime Prestige String" $s "PID $($proc.ProcessId) | $($proc.Name)" 5
            }
        }

        foreach ($rule in $script:Config.RuntimeInjectionPatterns) {
            foreach ($m in [regex]::Matches($cmd, $rule.Pattern)) {
                $token = Get-TokenAtPosition $tokens $m.Index
                $arg = if ($token) { [string]$token.Text } else { [string]$m.Value }
                $jars = @(Get-ReferencedJarPaths $arg)

                Add-Result "Runtime Injection" $rule.Label "PID $($proc.ProcessId) | ARG: $arg" $rule.Risk

                foreach ($jar in $jars) {
                    Add-Result "Referenced Runtime JAR" $rule.Label $jar $rule.Risk
                }
            }
        }
    }
}

function Resolve-ScanPaths {
    $paths = New-Object System.Collections.Generic.List[string]

    if ($Path -and (Test-Path -LiteralPath $Path)) {
        $paths.Add((Resolve-Path -LiteralPath $Path).Path)
    } else {
        foreach ($p in $script:Config.LauncherPaths) {
            if (Test-Path -LiteralPath $p) { $paths.Add($p) }
        }
    }

    return @($paths | Select-Object -Unique)
}

function Scan-Files($ScanPaths) {
    Section "File / Folder Prestige Artifact Scan"

    foreach ($root in $ScanPaths) {
        Write-Host "  Scanning: $root" -ForegroundColor DarkGray

        Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $file = $_

            foreach ($s in $script:Config.PrestigeStrings) {
                if ($file.Name -like "*$s*") {
                    Add-Result "Filename" $s $file.FullName 3
                }
            }

            if ($file.Extension -match "(?i)\.(json|txt|log|cfg|toml|properties|yml|yaml|xml|ini)$" -and $file.Length -lt 50MB) {
                foreach ($s in $script:Config.PrestigeStrings) {
                    if (Select-String -LiteralPath $file.FullName -Pattern $s -SimpleMatch -Quiet -ErrorAction SilentlyContinue) {
                        Add-Result "File String" $s $file.FullName 4
                    }
                }
            }
        }
    }
}

function Scan-Jars($ScanPaths) {
    Section "JAR Internal Prestige Entry Scan"

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    foreach ($root in $ScanPaths) {
        Get-ChildItem -LiteralPath $root -Recurse -Force -File -Filter "*.jar" -ErrorAction SilentlyContinue |
        ForEach-Object {
            $jar = $_.FullName

            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($jar)

                foreach ($entry in $zip.Entries) {
                    foreach ($s in $script:Config.PrestigeStrings) {
                        if ($entry.FullName -like "*$s*") {
                            Add-Result "JAR Entry" $s "$jar -> $($entry.FullName)" 5
                        }
                    }
                }

                $zip.Dispose()
            } catch {}
        }
    }
}

function Summary {
    Section "Scan Summary"

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
$scanPaths = Resolve-ScanPaths
Scan-Runtime
Scan-Files $scanPaths
Scan-Jars $scanPaths
Summary

Read-Host "Press ENTER to exit"