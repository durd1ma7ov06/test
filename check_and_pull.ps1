Set-Location "C:\Users\Mansur\Desktop\new"
$git = "C:\Program Files\Git\cmd\git.exe"

& $git fetch origin
$local = (& $git rev-parse HEAD).Trim()
$remote = (& $git rev-parse origin/main).Trim()

if ($local -ne $remote) {
    Write-Output "STATUS: UPDATES_FOUND"
    Write-Output "--- NEW COMMITS ---"
    & $git log HEAD..origin/main --stat
    Write-Output "--- PULLING CHANGES ---"
    & $git pull origin main
    Write-Output "--- RECENT CHANGES DIFF ---"
    & $git diff $local $remote
} else {
    Write-Output "STATUS: UP_TO_DATE"
}

