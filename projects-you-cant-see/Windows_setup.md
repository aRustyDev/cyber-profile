# Windows Setup Script

## What I did
Connected Remote Share Drives  
Tried to import bookmarks to Google Chrome
  - Had ALOT of troubles
Tried to import bookmarks to FireFox (x64 & x86)
Tried to Setup Outlook
  - Rules
  - Signatures
  - Add Mailboxes
Tried to add/install new Apps & add to taskbar
Manipulate File Explorer Options
Pin Remote Shares to Quick Access
Modify Startup programs

## What I Learned
How to modify browser settings in the registry
How to re-alias remote shares 
How chrome manages preferences, both for independent users & via policy based management.
How chrome secures the browser for the user.
How to edit/manipulate/read binary & hex data from powershell.

## Cool Snippets
**Setting Browser Settings in Registry**  
```powershell
Set-ItemProperty `
-Path "HKLM:\SOFTWARE\Policies\Google\Chrome" `
-Name "RestoreOnStartupURLs" `
-Value "https://sub.domain.top/path/to/file.[aspx,html,php...etc]"
```
**Getting Local Computer SID**
```powershell
((Get-LocalUser | Select-Object -First 1).SID).AccountDomainSID.ToString()
```
**Getting Local Volume ID/Serial**
```powershell
[regex]$regex = '.{8}-.{4}-.{4}-.{4}-.{12}'
$regex.Matches((Get-Volume -DriveLetter "C").UniqueId).value
```



## Sources
https://stackoverflow.com/questions/20935356/methods-to-hex-edit-binary-files-via-powershell  
https://www.adlice.com/google-chrome-secure-preferences/  
https://stackoverflow.com/questions/10633357/how-to-unpack-resources-pak-from-google-chrome  
https://source.chromium.org/chromium/chromium/src/+/master:rlz/lib/machine_id.cc  
