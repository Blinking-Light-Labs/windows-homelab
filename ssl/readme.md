# Extract Script

## How to Setup

We will need setup an OpenSSL app as by default windows does not have that.
This can be done by installing the app below with winget.

```pwsh
winget install ShiningLight.OpenSSL
```
## Adding OpenSSL to `PATH`

- Do a Windows Key + X
- Go to System --> Then click Advanced system settings
- Once the windows pops up go to Enviroment Variables at the bottom.
- Under user variables for `$USER` --> find `path` double click on it.
- Click new and add the path to OpenSSL, should be something like.
  -  `C:\Program Files\OpenSSL-Win64\bin`

After that you should be all set do a reboot just to be safe and you'll be ready to use the script.

# Script Usage

> [!NOTE]
> These Variables needs to be changed
>
> - $appName = "" # this should be changd to what the app is called.
> - $pfxPath = "" # Absoulte path of the cert
> - $outputDir = "\$appName" #absolute path to where you want eh certs to be saved. 

After all that is done you're ready to extract **_dem_** certs.



