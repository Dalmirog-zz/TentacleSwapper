#Reads the registry key "HKLM:\software\Octopus\Tentacle" 
#to figure out the path of Tentacle.exe on the machine
function Get-TentacleExePath{

    $InstallPath = Get-ItemProperty "HKLM:\software\Octopus\Tentacle" | select -ExpandProperty InstallLocation
    if(Test-Path "$InstallPath\Tentacle.exe"){
        return "$InstallPath\Tentacle.exe"
    }
    else{
        Write-error "Registry key referenced [$InstallPath] as Tentacle install location, but Tentacle.exe was not found there"
    }

}

#Get the name of the current tentacle instance based on the value of the variable $OctopusParameters["Octopus.Tentacle.Agent.ApplicationDirectoryPath"]
#This variable usually returns a value like this: C:\Octopus\Listening
#In that case, the name of the instance would be "Listening"
function Get-InstanceName{
    [System.IO.DirectoryInfo]$Apppath = $OctopusParameters["Octopus.Tentacle.Agent.ApplicationDirectoryPath"]

    #Scenario for the "(default)" Tentacle
    If($Apppath.FullName -eq "C:\Octopus"){
        return "Tentacle"
    }
    else{
        return $apppath.name
    }
}

#Reconfigures a listening Tentacle
function reconfigure-ListeningTentacle ($instanceName, $TentacleExePath, $Thumbprint){
    Write-Output "Reconfiguring intance [$InstanceName] on machine $env:COMPUTERNAME"   

    & $TentacleExePath configure --instance "$InstanceName" --reset-trust --console
    & $TentacleExePath configure --instance "$instanceName" --trust "$Thumbprint" --console
}

function reconfigure-PollingTentacle ($InstanceName, $TentacleExePath,$OctopusURL,$OctopusCommPort,$Username,$Password, $environmentName){
    Write-Output "Deleting intance [$InstanceName] on machine $env:COMPUTERNAME"

    #& $TentacleExePath service --instance $InstanceName --stop --uninstall --console
    & $TentacleExePath delete-instance --instance $InstanceName --console
    
    Write-Output "Creating intance [$InstanceName] on machine $env:COMPUTERNAME"
    
    & $TentacleExePath create-instance --instance $InstanceName --config "C:\Octopus\$InstanceName\Tentacle-$InstanceName.config" --console
    & $TentacleExePath new-certificate --instance $InstanceName --if-blank --console
    & $TentacleExePath configure --instance $InstanceName --reset-trust --console
    & $TentacleExePath configure --instance $InstanceName --home "C:\Octopus\$InstanceName" --app "C:\Octopus\Applications\$InstanceName" --port "10933" --noListen "True" --console
    & $TentacleExePath register-with --instance $InstanceName --server $OctopusURL --name $InstanceName --username $Username --password $Password --comms-style "TentacleActive" --server-comms-port $OctopusCommPort --force --environment $environmentName --role "webserver" --console
    #& $TentacleExePath service --instance $InstanceName --install --start --console
}


If($OctopusParameters["Octopus.Machine.CommunicationStyle"] -eq "TentaclePassive"){
    reconfigure-ListeningTentacle -instanceName (Get-InstanceName) -TentacleExePath (Get-TentacleExePath) -Thumbprint $TargetThumbprint
}

if($OctopusParameters["Octopus.Machine.CommunicationStyle"] -eq "TentacleActive"){
    reconfigure-PollingTentacle -InstanceName (Get-InstanceName) -TentacleExePath (Get-TentacleExePath) -OctopusURL $TargetOctopusURL -OctopusCommPort $TargetOctopusCommPort -Username $TargetUsername -Password $TargetPassword -EnvironmentName $OctopusParameters['Octopus.Environment.Name']
}#>

#Localhost
#reconfigure-PollingTentacle -InstanceName "Polling" -TentacleExePath 'C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe' -OctopusURL "http://localhost" -OctopusCommPort "10943" -Username "dalmiro.granias" -Password "password" -EnvironmentName "TentacleSwapper - Dev"

#Localhost 81
#reconfigure-PollingTentacle -InstanceName "Polling" -TentacleExePath 'C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe' -OctopusURL "http://localhost:81" -OctopusCommPort 10944 -Username "dalmiro.granias" -Password "password" -EnvironmentName "TentacleSwapper - Dev"