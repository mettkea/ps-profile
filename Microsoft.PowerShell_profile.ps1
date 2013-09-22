########################################################
# mettkea PowerShell Profile
#  v1.0 (2013-09-22)
########################################################

########################################################
########################################################
# Load Script Libraries

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module posh-git
Import-Module PSCX

Pop-Location

########################################################
########################################################
# Environment

Enable-GitColors

$computer = get-content env:computername
set-variable tools "C:\tools"
set-variable project "$env:SystemDrive\project"
set-variable desktop "C:\documents and settings\$env:username\Desktop"
Write-Host "Setting environment:  compy=$computer" -foregroundcolor cyan

########################################################
########################################################
# Aliases

set-alias grep select-string;
set-alias wide format-wide;
set-alias np "C:\Program Files (x86)\Notepad++\notepad++.exe";
set-alias z "C:\tools\7-Zip\7z.exe";
set-alias up update-profile;
set-alias gb git-branch;
set-alias mci mvn-clean-install;
set-alias mcid mvn-clean-install-debug;
set-alias tc time-card;

########################################################
########################################################
# Prompt

function prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    $host.ui.rawui.foregroundColor = "DarkGreen"
    $path = ""
    $pathbits = ([string]$pwd).split("\", [System.StringSplitOptions]::RemoveEmptyEntries)
    if($pathbits.length -eq 1) {
        $path = $pathbits[0] + "\"
    } else {
        $path = $pathbits[$pathbits.length - 1]
    }
    $userTitle = $env:username + '@' + [System.Environment]::MachineName + ' [' + $(Get-Location) + ']'
    $userLocation = "[" + $env:username + '@' + [System.Environment]::MachineName + " $path"
    $host.UI.RawUi.WindowTitle = $userTitle
    Write-Host($userLocation) -nonewline -foregroundcolor Green
    Write-Host(']$') -nonewline -foregroundcolor Green
    $LASTEXITCODE = $realLASTEXITCODE
    return " "
}

########################################################
########################################################
# Functions

function update-profile {
    $script_dir = join-path $env:home "mettkea-scripts\powershell-profile"
    $home_dir = join-path $env:userprofile "Documents\WindowsPowerShell"
    xcopy /S /Y $script_dir $home_dir
}

function touch([Parameter(Mandatory=$true)]$file) {
    set-content -Path $file -Value ($null)
}

function list-env {
    gci env: | sort name
}

function ll {
    param ($dir = ".", $all = $false)

    $origFg = $host.ui.rawui.foregroundColor
    if ( $all ) { $toList = ls -force $dir }
    else { $toList = ls $dir }

    foreach ($Item in $toList)  {
        Switch ($Item.Extension)  {
            ".Exe" {$host.ui.rawui.foregroundColor = "Yellow"}
            ".cmd" {$host.ui.rawui.foregroundColor = "Red"}
            ".bat" {$host.ui.rawui.foregroundColor = "Red"}
            ".rb" {$host.ui.rawui.foregroundColor = "Magenta"}
            Default {$host.ui.rawui.foregroundColor = $origFg}
        }
        if ($item.Mode -ne $null -and $item.Mode.StartsWith("d")) {$host.ui.rawui.foregroundColor = "Green"}
        $item
    }
    $host.ui.rawui.foregroundColor = $origFg
}

function df {
    Get-WmiObject Win32_LogicalDisk -Filter "drivetype=3" |
    Format-Table @{Label="Drive";Expression={$_.DeviceID}},`
    @{Label="Size(G)";Expression={ "{0:0.00}" -f ($_.Size/1gb) }},`
    @{Label="Used(G)";Expression={ "{0:0.00}" -f `
    (($_.Size/1gb)-($_.FreeSpace/1gb))}},`
    @{Label="Avail(G)";Expression={ "{0:0.00}" -f ($_.FreeSpace/1gb)}},`
    @{Label="Use(%)";Expression={ "{0:0.00}" -f `
    ((($_.Size/1gb)-($_.FreeSpace/1gb))`
    /($_.Size/1gb) * 100)}} -AutoSize
}

function du($dir=".") {
  get-childitem $dir |
    % { $f = $_ ;
        get-childitem -r $_.FullName |
           measure-object -property length -sum |
             select @{Name="Name";Expression={$f}},Sum}
}

function get-ipconfig {
    $strComputer = "."
    $colItems = Get-wmiobject -class "Win32_NetworkAdapterConfiguration" `
    -computername $strComputer | Where{$_.IpEnabled -Match "True"}
    foreach ($objItem in $colItems) {
       write-host "MAC Address : " $objItem.MACAddress
       write-host "IPAddress : " $objItem.IPAddress
       write-host "IPAddress : " $objItem.IPEnabled
       write-host "DNS Servers : " $objItem.DNSServerSearchOrder
       Write-host ""
    }
}

function get-svn-url {
    $url = svn info | grep "^URL:" | foreach {$_.line.split(" ")[1].trim()}
    set-clipboard($url)
    write-host $url
}

function copy-path($file) {
    set-clipboard((gi $file).FullName)
}

function path {
   write-host $env:path
}

function wait-for-process($name) {
    if ((get-process | grep $name) -ne $null) {
        write-host "Waiting for $name to shutdown..."
        wait-process -name $name
    }
}

function wait-for-process-to-start($name) {
    while ((get-process | grep $name) -eq $null) {
        write-host "Waiting for $name to start..."
        start-sleep -m 500
    }
}

function find-file([Parameter(Mandatory=$true)][ValidateScript({test-path $_})]$basedir, [Parameter(Mandatory=$true)]$name) {
    $dir = get-childitem $basedir -recurse
    $list = $dir | where {$_.name -like $name}
    $list | format-table FullName
}

function get-batchfile($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

function visual-studio-env {
    $vs90comntools = (Get-ChildItem env:VS90COMNTOOLS).Value
    $batchFile = [System.IO.Path]::Combine($vs90comntools, "vsvars32.bat")
    get-batchfile $BatchFile
}

function vlc {
    start-process "C:\Program Files\VideoLAN\VLC\vlc.exe"
}

function rf($dir) {
    if (test-path $dir) {
        rm -Recurse -Force $dir
    }
}

function convert-epoch($epoch) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epoch))
}

function mvn-clean-install {
    mvn clean install
}

function mvn-clean-install-debug {
    mvn clean install -X
}  

function time-card {
	t w -v all > c:\project\o.txt | np c:\project\o.txt
}

function measure-runs {
    param (
        [int]$numberRuns = $(throw "numberRuns is required"),
        [ScriptBlock]$beforeRun = $null,
        [ScriptBlock]$run = {}
       )
    $times = @()
    for($i=1;$i -le $numberRuns;$i++) { 
        Write-Host -NoNewline ("[" + "{0,4}" -f $i + " / " + "{0,4}" -f $numberRuns + "] ")
 
        if($beforeRun -ne $null) {
            Write-Host -NoNewline ("(Preparing... ) ")
            &$beforeRun | Out-Null
        }
        Write-Host -NoNewline ("Running...")
 
        $seconds = (Measure-Command $run).TotalSeconds
        $times += $seconds
 
        Write-Host -NoNewline (" {0,14:N4} seconds" -f $seconds) 
        Write-Host
    }
    $times | Measure-Object -average | Select-Object Average
}

function remove-all-gems {
     gem list | %{$_.split(' ')[0]} | %{gem uninstall -Iax $_ }
}

########################################################
########################################################
# Git specific

function git-branch {
    git rev-parse --abbrev-ref HEAD
}

function sw-git-user([switch]$github, [switch]$dcc) {
    $email = ""
    if ($github.isPresent) {
        $email = "mettke@gmail.com"
    } 
    if ($email) {
        git config --global user.email $email
    }
}

function install-posh-git {
    (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
    install-module posh-git
}
