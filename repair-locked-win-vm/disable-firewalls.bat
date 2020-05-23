@echo OFF
rem This script loads the registrty from the drive of the locked out VM
rem and disables all three firewall policies.

echo "Loading hive..."
powershell reg load HKEY_LOCAL_MACHINE\tmp E:\Windows\System32\config\SYSTEM
echo "Disabling firewalls...

powershell Set-ItemProperty  HKLM:\tmp\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile -Name EnableFirewall -Value 0
powershell Set-ItemProperty  HKLM:\tmp\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile -Name EnableFirewall -Value 0
powershell Set-ItemProperty  HKLM:\tmp\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile -Name EnableFirewall -Value 0
powershell [gc]::Collect() 
echo "Unloading hive..."
powershell reg unload HKEY_LOCAL_MACHINE\tmp

echo "Fixing bootsect..."
set PATH=C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools\x86\BCDBoot;%PATH%
bootsect /nt60 D: /mbr
C:\windows\system32\bcdboot.exe E:\Windows /s D:
bcdedit /store D:\Boot\BCD /set {default} device partition=E:
bcdedit /store D:\Boot\BCD /set {default} osdevice partition=E:
bcdedit /store D:\Boot\BCD /set {bootmgr} device partition=E:
echo "Done."
pause
