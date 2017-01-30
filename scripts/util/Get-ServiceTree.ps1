cls


function Get-ChildService {
  param (
    $ParentService,
    $Level
  )

  Get-Service -CN . |? { $_.status -eq 'running' -and (($_.RequiredServices|?{ $_.Name -eq $ParentService.Name }).Count -gt 0) } |% {
    $S2 = $_;

    Write-host " $(New-Object String "-", $Level) $($S2.Name)"
    Get-ChildService -ParentService $S2 ($Level + 1)
    
    #Restart-Service $S2.name -Force
  }
}

Get-Service -CN . |? { $_.status -eq 'running' -and ($_.Name -match "^xenv") } |% {
    $S1 = $_
    Write-host $S1.Name
    Restart-Service $S1.name -Force
}

exit

Get-Service -CN . |? { $_.status -eq 'running' -and -not($_.RequiredServices) } |% {
    $S1 = $_
    Write-host $S1.Name
    Get-ChildService $S1 1
    Restart-Service $S1.name -Force
}
