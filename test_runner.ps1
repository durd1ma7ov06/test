Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        STILLS IOS TEST BUILD - ARXITEKTURA VA KOD TESTI  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$basePath = "C:\Users\Mansur\Desktop\new\ios-test"
$errors = 0
$warnings = 0

function Assert-FileExists($path, $description) {
    if (Test-Path $path) {
        Write-Host " [PASS] $description mavjud ($((Get-Item $path).Name))" -ForegroundColor Green
        return $true
    } else {
        Write-Host " [FAIL] $description TOPILMADI: $path" -ForegroundColor Red
        $script:errors++
        return $false
    }
}

function Assert-ContentContains($path, $pattern, $description) {
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content -match $pattern) {
            Write-Host " [PASS] $($description) - mos keldi" -ForegroundColor Green
            return $true
        } else {
            Write-Host " [FAIL] $($description) - '$pattern' topilmadi!" -ForegroundColor Red
            $script:errors++
            return $false
        }
    }
    return $false
}

Write-Host "`n1. FAYLLAR VA MODULLARNING MAVJUDLIGI TEKSHIRUVI:" -ForegroundColor Yellow
Assert-FileExists "$basePath\project.yml" "XcodeGen project configuration"
Assert-FileExists "$basePath\generate_project.sh" "Loyiha yaratish skripti"
Assert-FileExists "$basePath\StillsTest\Shared.swift" "Shared.swift (App Groups)"
Assert-FileExists "$basePath\StillsTest\StillsTestApp.swift" "StillsTestApp (Kirish nuqtasi)"
Assert-FileExists "$basePath\StillsTest\ContentView.swift" "ContentView (UI)"
Assert-FileExists "$basePath\StillsTest\ListenView.swift" "ListenView (Audio/Bonus)"
Assert-FileExists "$basePath\StillsTest\CalmAudioPlayer.swift" "CalmAudioPlayer (Sintezator)"
Assert-FileExists "$basePath\StillsMonitor\DeviceActivityMonitorExtension.swift" "Monitor Extension"
Assert-FileExists "$basePath\StillsShieldConfig\ShieldConfigurationExtension.swift" "Shield Config Extension"
Assert-FileExists "$basePath\StillsShieldAction\ShieldActionExtension.swift" "Shield Action Extension"

Write-Host "`n2. XAVFSIZLIK VA ENTITLEMENTS TEKSHIRUVI:" -ForegroundColor Yellow
Assert-FileExists "$basePath\StillsTest\StillsTest.entitlements" "StillsTest Entitlements"
Assert-FileExists "$basePath\StillsMonitor\StillsMonitor.entitlements" "StillsMonitor Entitlements"
Assert-FileExists "$basePath\StillsShieldConfig\StillsShieldConfig.entitlements" "StillsShieldConfig Entitlements"
Assert-FileExists "$basePath\StillsShieldAction\StillsShieldAction.entitlements" "StillsShieldAction Entitlements"

Assert-ContentContains "$basePath\StillsTest\StillsTest.entitlements" "group\.com\.stills\.app" "StillsTest App Group identifikatori"
Assert-ContentContains "$basePath\StillsMonitor\StillsMonitor.entitlements" "group\.com\.stills\.app" "StillsMonitor App Group identifikatori"
Assert-ContentContains "$basePath\StillsTest\StillsTest.entitlements" "com\.apple\.developer\.family-controls" "Family Controls ruxsati"

Write-Host "`n3. EXTENSION PLUGINS VA INFO.PLIST TEKSHIRUVI:" -ForegroundColor Yellow
Assert-FileExists "$basePath\StillsTest\Info.plist" "Main App Info.plist"
Assert-FileExists "$basePath\StillsMonitor\Info.plist" "Monitor Info.plist"
Assert-FileExists "$basePath\StillsShieldConfig\Info.plist" "ShieldConfig Info.plist"
Assert-FileExists "$basePath\StillsShieldAction\Info.plist" "ShieldAction Info.plist"

Assert-ContentContains "$basePath\StillsMonitor\Info.plist" "com\.apple\.deviceactivity\.monitor-extension" "Monitor Extension Identifier"
Assert-ContentContains "$basePath\StillsShieldConfig\Info.plist" "com\.apple\.ManagedSettingsUI\.shield-configuration-service" "Shield Config Extension Identifier"
Assert-ContentContains "$basePath\StillsShieldAction\Info.plist" "com\.apple\.ManagedSettings\.shield-action-service" "Shield Action Extension Identifier"

Write-Host "`n4. PROTOKOL VA BOG'LANISHLARNING SINXRONLIGI (CRITICAL LOGIC):" -ForegroundColor Yellow
# Notification route must match between ShieldAction and AppDelegate
Assert-ContentContains "$basePath\StillsShieldAction\ShieldActionExtension.swift" '"route":\s*"listen"' "ShieldAction route = 'listen'"
Assert-ContentContains "$basePath\StillsTest\StillsTestApp.swift" 'route\s*==\s*"listen"' "AppDelegate ushlash route == 'listen'"
# App Group in code must match entitlements
Assert-ContentContains "$basePath\StillsTest\Shared.swift" 'group\.com\.stills\.app' "Shared.swift App Group"
# Threshold early-fire bug check
Assert-ContentContains "$basePath\StillsMonitor\DeviceActivityMonitorExtension.swift" 'isRearm:\s*true' "DeviceActivityMonitor erta signalni qayta qurollantirish"
Assert-ContentContains "$basePath\StillsTest\Shared.swift" 'if\s*!isRearm' "Shared.swift: isRearm vaqtida armedAt saqlanishi"

Write-Host "`n5. XULOSA:" -ForegroundColor Yellow
if ($errors -eq 0) {
    Write-Host ">>> BARCHA TEKSHIRUVLAR MUVAFFAQIYATLI O'TDI (0 TA XATOLIK)! <<<" -ForegroundColor Green
    Write-Host "Loyiha arxitekturasi va kodi to'liq to'g'ri sozlangan, Xcode'da ochishga tayyor." -ForegroundColor Green
} else {
    Write-Host ">>> TEKSHIRUVDA $errors TA XATOLIK ANIQLANDI! <<<" -ForegroundColor Red
}
