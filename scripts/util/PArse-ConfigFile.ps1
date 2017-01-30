cls
$nl = [System.Environment]::NewLine

$sections = @()
$section = ""
Get-Content -LiteralPath E:\XENV\_xenv\0.1.0\conf\util\openssl\ca.conf |% {
    if(!$_.startswith("# ") -and !$_.startswith("##") -and $_.Trim() -ne "#" -and ![string]::IsNullOrEmpty($_.Trim())) {
        if($_.startswith("[")) {
            if(![string]::IsNullOrEmpty($section)) {
            # + $nl
                $section = $section.Trim()
                if($section[$section.Length -1] -eq ",") {
                    $section = $section.Substring(0, $section.Length - 1)
                }
                $section = ($section + "  ]")
                $section = ($section + "}," )
                $section = $section.Replace("} ", "}$nl").Replace("{ ", "{$nl").Replace(", ", ",$nl").Replace("[", "[$nl").Replace("]", "]$nl").Replace("true ", "true$nl").Replace("false ", "false$nl")
                $sections = $sections + $section
                $section = ""
            }

            $sectionName = $_.Replace("[", "").Replace("]", "").Trim()
            $section = ($section + "{ ")
            $section = ($section + "  `"key`": `"$sectionName`", ")
            $section = ($section + "  `"settings`": [")
        } else {
            $settingLine = $_
            $enabled = $true
            if($_.startswith("#"))
            {
                $enabled = $false
                $settingLine = $settingLine.Substring(1)
            }

            $settingLineParts = $settingLine.Split("=")
            $key = $settingLineParts[0].Trim()
            $value = $settingLineParts[1].Trim().Replace("`"", "").Replace(", ", ",")
            #Write-Host $value
            $section = ($section + "    {")
            $section = ($section + "      `"key`": `"$key`",")
            $section = ($section + "      `"value`": `"$value`",")
            $section = ($section + "      `"enabled`": $($enabled.ToString().ToLower())")
            $section = ($section + "   },")
        }
    }
}

$sections | % {
    #Write-Host "SECTION:$nl"
    Write-Host ($_ )
}