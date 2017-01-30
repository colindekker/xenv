cls
Get-ChildItem -LiteralPath "E:\XENV\server\apache\_xenv" -Filter "*.conf" -Recurse |% {
    $clean = @()
    Get-Content -LiteralPath $_.FullName | % {
        if(!$_.startswith("# ") -and !$_.startswith("##") -and $_.Trim() -ne "#" -and ![string]::IsNullOrEmpty($_.Trim())) {
            Write-Host $_
            $clean = $clean + $_
        }
    }

    $clean | Out-File ($_.FullName + ".clean")
}