Set-Location "C:\Users\Mansur\Desktop\new"
$git = "C:\Program Files\Git\cmd\git.exe"

& $git fetch origin
$incoming = & $git log HEAD..origin/main --oneline

if ($incoming) {
    Write-Output "STATUS: UPDATES_FOUND"
    Write-Output "--- NEW COMMITS ---"
    & $git log HEAD..origin/main --stat
    Write-Output "--- PULLING CHANGES ---"
    & $git pull --rebase origin main
    Write-Output "--- PULL COMPLETE ---"
} else {
    Write-Output "STATUS: UP_TO_DATE"
}
