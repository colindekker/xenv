cls
Get-ChildItem -Path E:\XENV -Recurse -Depth 2  |? { 
    ( $_.FullName -match "^E:\\XENV\\runtime" -or $_.FullName -match "^E:\\XENV\\server") `
    -and  $_.FullName -notmatch "\\on$" `
    -and $_.PsIsContainer 
} | Select FullName | Sort | % {
    $childPath = $_.FullName.Substring(8)
    if((Get-Item "E:\XENV.DATA\$childPath" -ErrorAction SilentlyContinue) -eq $null) {
        New-Item "E:\XENV.DATA\$childPath" -ItemType Directory 
    }

    if((Get-Item "E:\XENV.TMP\$childPath" -ErrorAction SilentlyContinue) -eq $null) {
        New-Item "E:\XENV.TMP\$childPath" -ItemType Directory 
    }

    if((Get-Item "E:\XENV.TMP\cache\$childPath" -ErrorAction SilentlyContinue) -eq $null) {
        New-Item "E:\XENV.TMP\cache\$childPath" -ItemType Directory 
    }

    if((Get-Item "E:\XENV.TMP\logs\$childPath" -ErrorAction SilentlyContinue) -eq $null) {
        New-Item "E:\XENV.TMP\logs\$childPath" -ItemType Directory 
    }
}
