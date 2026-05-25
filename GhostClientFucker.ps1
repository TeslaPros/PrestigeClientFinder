[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$currentFont = (Get-ItemProperty "HKCU:\Console" -ErrorAction SilentlyContinue).FaceName
if ($currentFont -notmatch "NSimSun|Gothic|Noto") {
    Write-Host "  [!] Tip: Set your terminal font to 'NSimSun' to display all elements correctly." -ForegroundColor DarkYellow
    Write-Host
}

$Banner = @"
  ████████╗███████╗███████╗██╗      █████╗ ██████╗ ██████╗  ██████╗ 
  ╚══██╔══╝██╔════╝██╔════╝██║     ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗
     ██║   █████╗  ███████╗██║     ███████║██████╔╝██████╔╝██║   ██║
     ██║   ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔══██╗██║   ██║
     ██║   ███████╗███████║███████╗██║  ██║██║     ██║  ██║╚██████╔╝
     ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ 
                                                                    
   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗  ██████╗██╗     ██╗███████╗███╗   ██╗████████╗
  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝ ██╔════╝██║     ██║██╔════╝████╗  ██║╚══██╔══╝
  ██║  ███╗███████║██║   ██║███████╗   ██║    ██║     ██║     ██║█████╗  ██╔██╗ ██║   ██║   
  ██║   ██║██╔══██║██║   ██║╚════██║   ██║    ██║     ██║     ██║██╔══╝  ██║╚██╗██║   ██║   
  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║    ╚██████╗███████╗██║███████╗██║ ╚████║   ██║   
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝     ╚═════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
                                                                                            
  -> FUCKER EDITION <-
"@

function Write-Row {
    param([string]$char, [int]$count, [System.ConsoleColor]$color)
    Write-Host ($char * $count) -ForegroundColor $color
}

Write-Host $Banner -ForegroundColor Cyan
Write-Host ""
Write-Host "  ⚡ Powered by " -ForegroundColor Gray -NoNewline
Write-Host "TeslaPro " -ForegroundColor Cyan -NoNewline
Write-Host "|| " -ForegroundColor DarkGray -NoNewline
Write-Host "Discord: " -ForegroundColor Gray -NoNewline
Write-Host "teamwsf " -ForegroundColor White -NoNewline
Write-Host "|| " -ForegroundColor DarkGray -NoNewline
Write-Host "Credits to: " -ForegroundColor DarkGray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor DarkGray
Write-Host ""
Write-Row "─" 85 DarkGray
Write-Host

Write-Host "  [>] Enter the path to the mods folder: " -NoNewline -ForegroundColor White
Write-Host "(Press Enter for default)" -ForegroundColor DarkGray
$modsPath = Read-Host "  "
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "  [+] Starting with default location: " -NoNewline -ForegroundColor Gray
    Write-Host $modsPath -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "  [X] ERROR: Invalid Path!" -ForegroundColor Red
    Write-Host "  [-] The specified directory does not exist or is inaccessible." -ForegroundColor Yellow
    Write-Host
    exit 1
}

Write-Row "═" 85 DarkCyan
Write-Host "  [►] SCAN MODE ACTIVATED ON: $modsPath" -ForegroundColor Green
Write-Row "═" 85 DarkCyan
Write-Host

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "  ┌── { Minecraft Runtime Status }" -ForegroundColor Cyan
        Write-Host "  ├── Process: $($mcProcess.Name) (PID $($mcProcess.Id))" -ForegroundColor Gray
        Write-Host "  ├── Started on: $startTime" -ForegroundColor Gray
        Write-Host "  └── Uptime:     $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "JumpReset", "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "Virgin", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill",  "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean", "Argon",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "Grim", "grim", "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion", "dev.gambleclient", "obfuscatedAuth",
    "xyz.greaj", "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "AutoHitCrystal", 
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "anchortweaks", "AirAnchor",
    "AutoTotem", "autototem", "InventoryTotem", "HoverTotem",
    "AutoPot", "autopot", "AutoArmor", "autoarmor", "ShieldDisabler", "ShieldBreaker",
    "AutoDoubleHand", "AutoClicker", "AutoMace", "MaceSwap", "SpearSwap",
    "Donut", "JumpReset", "axespam", "axe spam", "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot", "Silent Rotations", "SilentRotations",
    "FakeInv", "FakeLag", "pingspoof", "ping spoof", "fakePunch", "Fake Punch",
    "webmacro", "AntiWeb", "AutoWeb", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "PackSpoof", "Antiknockback",
    "AuthBypass", "obfuscatedAuth", "BaseFinder", "invsee", "ItemExploit", "FreezePlayer",
    "LWFH Crystal", "KeyPearl", "LootYeeter", "FastPlace", "AutoBreach", "KillAura", 
    "ClickAura", "MultiAura", "ForceField", "AimBot", "AutoAim", "SilentAim", "AimLock", 
    "CrystalAura", "AnchorAura", "AnchorFill", "BedAura", "AutoBed", "BowAimbot", 
    "AutoCrit", "ReachHack", "ExtendReach", "AntiKB", "NoKnockback", "VelocitySpoof", 
    "OffhandTotem", "AutoWeapon", "Burrow", "SelfTrap", "HoleFiller", "WTap", "TargetStrafe", 
    "FlyHack", "PacketFly", "SpeedHack", "BHop", "NoFallDamage", "StepHack", "WaterWalk", 
    "NoSlow", "WallHack", "ScaffoldWalk", "Nuker", "GhostHand", "PlaceAssist", 
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP", "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "NewChunks", "ChestStealer", "InvManager", "AutoSprint", 
    "FakeNick", "PopSwitch", "FakeLatency", "GameSpeed", "SelfDestruct", "SessionStealer", 
    "TokenLogger", "TokenGrabber", "DiscordToken", "RemoteAccess", "ReverseShell", 
    "StashFinder", "JNativeHook", "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline", "wtf/moonlight", "net/ccbluex", 
    "org/chainlibs/module/impl/modules", "doomsdayclient", "DoomsdayClient", 
    "novaclient", "vape.gg", "vapeclient", "VapeClient", "VapeLite", "intent.store", 
    "rise.today", "meteor-client", "meteorclient", "liquidbounce", "fdp-client", 
    "aristois", "impactclient", "skilled", "astolfo", "futureClient", "rusherhack"
)

# FIXED: Completely removed the duplicate case-insensitive key 'DoomsdayClient'
$clientFrameworks = @{
    "meteor-client" = "Meteor Client Core"; "meteorclient" = "Meteor Client Core"; "meteordevelopment" = "Meteor Client API"
    "vape.gg" = "Vape Client Injectable"; "vapeclient" = "Vape Client Framework"; "VapeLite" = "Vape Lite Profile"
    "novaclient" = "Nova Client Leaks"; "api.novaclient.lol" = "Nova Web Backend"; "cc/novoline" = "Novoline Client Integration"
    "doomsdayclient" = "Doomsday PvP Client"
    "liquidbounce" = "LiquidBounce Utility Mod"; "net.ccbluex" = "LiquidBounce Package Structure"
    "fdp-client" = "FDP Bypass Client"; "aristois" = "Aristois Hack Menu"; "impactclient" = "Impact Utility Engine"
    "futureClient" = "Future Client Framework"; "rusherhack" = "Rusherhack Utility Pack"; "astolfo" = "Astolfo Premium Client"
}

$patternRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

function Get-FileSHA1 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA1).Hash
}

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                         { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord CDN" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub Releases" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        elseif ($url -match "doomsdayclient\.com")                               { return "Doomsday Website" }
        else {
            if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
            return $url
        }
    }
    return "Unknown / Local Transfer"
}

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch { }
    return @{ Name = ""; Slug = "" }
}

function Invoke-ModScan {
    param([string]$FilePath)
    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $detectedClients = [System.Collections.Generic.HashSet[string]]::new()

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
        }

        $allEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $archive.Entries) { $allEntries.Add($e) }

        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $ms = New-Object System.IO.MemoryStream; $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }

        foreach ($entry in $allEntries) {
            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream; $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)

                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s)) { 
                            [void]$foundStrings.Add($s)
                            if ($clientFrameworks.ContainsKey($s)) { [void]$detectedClients.Add($clientFrameworks[$s]) }
                        }
                    }
                } catch { }
            }
        }
        $archive.Dispose()
    } catch { }
    return @{ Patterns = $foundPatterns; Strings = $foundStrings; ClientFrames = $detectedClients }
}

function Invoke-BypassScan {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $nestedJars = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outerClasses = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })

        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $flags.Add("Hollow Shell Container (Wraps isolated inner assemblies)")
        }

        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match "\.class$") {
                try {
                    $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream; $st.CopyTo($ms); $st.Close()
                    $bytes = $ms.ToArray(); $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)

                    if ($ascii.Contains("java/lang/Runtime") -and $ascii.Contains("exec")) { $flags.Add("External Process Execution (Runtime.exec)") }
                    if ($ascii.Contains("java/net/URL") -and $ascii.Contains("openStream")) { $flags.Add("Remote Resource Fetching (URL.openStream)") }
                    if ($ascii.Contains("HttpURLConnection") -and $ascii.Contains("POST")) { $flags.Add("Data Transport Exfiltration Layer (HTTP POST)") }
                    if ($ascii.Contains("org/jnativehook")) { $flags.Add("Native Hooks (Global Keyboard Logger Tracking)") }
                } catch { }
            }
        }
        $zip.Dispose()
    } catch { }
    return $flags
}

$files = Get-ChildItem -Path $modsPath -Filter *.jar -File -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Host "  [i] No target items discovered." -ForegroundColor Yellow
    exit 0
}

$flaggedMods = [System.Collections.Generic.List[object]]::new()
$cleanMods   = [System.Collections.Generic.List[object]]::new()
$totalFiles  = $files.Count
$currentIndex = 0

Write-Host "  [>] Commencing sequence pipeline on $totalFiles elements..." -ForegroundColor Cyan
Write-Host

foreach ($file in $files) {
    $currentIndex++
    $percent = [math]::Round(($currentIndex / $totalFiles) * 100)
    Write-Progress -Activity "TeslaPro Ghost Scan" -Status "Running: $($file.Name)" -PercentComplete $percent

    $sha1 = Get-FileSHA1 -Path $file.FullName
    $source = Get-DownloadSource -Path $file.FullName

    $modrinth = Query-Modrinth -Hash $sha1
    if ($modrinth.Name) {
        $cleanMods.Add(@{ Name = $file.Name; Details = "Verified Modrinth Archive: $($modrinth.Name)" })
        continue
    }

    $scan = Invoke-ModScan -FilePath $file.FullName
    $bypass = Invoke-BypassScan -FilePath $file.FullName

    if ($scan.Patterns.Count -gt 0 -or $scan.Strings.Count -gt 0 -or $bypass.Count -gt 0) {
        $clientTag = "Custom Modified / Independent Hack"
        if ($scan.ClientFrames.Count -gt 0) { $clientTag = ($scan.ClientFrames | ForEach-Object {$_}) -join ", " }

        $flaggedMods.Add(@{
            File       = $file.Name
            Source     = $source
            Client     = $clientTag
            Indicators = @($scan.Patterns + $scan.Strings + $bypass)
        })
    } else {
        $cleanMods.Add(@{ Name = $file.Name; Details = "No anomalies identified inside target binaries." })
    }
}

# ═════════════════════════════════════════════════════════════════════════════════════════
#                      ✨ TESLAPRO GHOSTCLIENTFUCKER EXEC REPORT SUMMARY ✨
# ═════════════════════════════════════════════════════════════════════════════════════════
Clear-Host
Write-Host $Banner -ForegroundColor Cyan
Write-Host "`n"

Write-Row "═" 90 Cyan
Write-Host "                 TESLAPRO GHOSTCLIENTFUCKER - DETAILED SCAN REPORT                  " -ForegroundColor White
Write-Row "═" 90 Cyan
Write-Host ""
Write-Host "  [+] TARGET DIRECTORY : " -NoNewline -ForegroundColor Gray; Write-Host "$modsPath" -ForegroundColor White
Write-Host "  [+] TOTAL SCANNED    : " -NoNewline -ForegroundColor Gray; Write-Host "$totalFiles JAR files examined" -ForegroundColor White
Write-Host "  [+] INFRA STATUS     : " -NoNewline -ForegroundColor Gray
if ($flaggedMods.Count -gt 0) {
    Write-Host "COMPROMISED - CHEAT MODIFICATIONS OR GHOST CLIENTS DETECTED" -ForegroundColor Red
} else {
    Write-Host "CLEAN - ALL FILES VALIDATED AGAINST TRUSTED STANDARDS" -ForegroundColor Green
}
Write-Host ""

Write-Row "─" 90 DarkGray
Write-Host " 🛑 FLAGGED SOFTWARE & INJECTED CLIENT ASSEMBLIES ($($flaggedMods.Count) Files Flagged)" -ForegroundColor Red
Write-Row "─" 90 DarkGray
Write-Host ""

if ($flaggedMods.Count -eq 0) {
    Write-Host "  📋 No malicious modules or cheat client payloads found in the target directory." -ForegroundColor Green
    Write-Host ""
} else {
    foreach ($mod in $flaggedMods) {
        Write-Host "  [💥] DETECTED MOD : " -NoNewline -ForegroundColor White
        Write-Host "$($mod.File)" -ForegroundColor Red
        
        Write-Host "       ├── Client Base/Framework : " -NoNewline -ForegroundColor Gray
        Write-Host "$($mod.Client)" -ForegroundColor Yellow
        
        Write-Host "       ├── Network Source Stream : " -NoNewline -ForegroundColor Gray
        Write-Host "$($mod.Source)" -ForegroundColor DarkYellow
        
        Write-Host "       └── Signature Triggers    : " -NoNewline -ForegroundColor Gray
        $indList = ($mod.Indicators | ForEach-Object { "'$_'" }) -join ", "
        Write-Host "[$indList]" -ForegroundColor DarkCyan
        Write-Host ""
    }
}

Write-Row "─" 90 DarkGray
Write-Host " ✅ SAFE & INDEPENDENT VERIFIED MODS ($($cleanMods.Count) Files Cleared)" -ForegroundColor Green
Write-Row "─" 90 DarkGray
Write-Host ""

if ($cleanMods.Count -eq 0) {
    Write-Host "  [!] Zero modules returned verified status benchmarks or repository matches." -ForegroundColor Orange
    Write-Host ""
} else {
    foreach ($c in $cleanMods) {
        Write-Host "  [✓] PASSED: " -NoNewline -ForegroundColor Green
        Write-Host "$($c.Name) " -NoNewline -ForegroundColor White
        Write-Host "➔ $($c.Details)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Row "═" 90 Cyan
Write-Host "  📊 FINAl ANALYSIS METRICS MATRIX:" -ForegroundColor White
Write-Host "  ────────────────────────────────"
Write-Host "  • Total Examined Elements   : " -NoNewline -ForegroundColor Gray; Write-Host "$totalFiles" -ForegroundColor White
Write-Host "  • Rogue/Flagged Items Found : " -NoNewline -ForegroundColor Gray; Write-Host "$($flaggedMods.Count)" -ForegroundColor Red
Write-Host "  • Clean/Verified Packages   : " -NoNewline -ForegroundColor Gray; Write-Host "$($cleanMods.Count)" -ForegroundColor Green
Write-Host ""
Write-Row "═" 90 Cyan
Write-Host ""
Write-Host "  ✨ System Analysis Complete. Thanks for using TeslaPro's Ghost client fucker!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👤 Creator   : " -ForegroundColor White -NoNewline
Write-Host "TeslaPro" -ForegroundColor Cyan
Write-Host "  📱 Discord   : " -ForegroundColor White -NoNewline
Write-Host "teamwsf" -ForegroundColor White
Write-Host "  📝 Credits to: " -ForegroundColor DarkGray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  [i] Forensic scan run terminated. Press any key to safely dispose this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")