#Hilton Automated SunSystems backup Powershell script

##Getting Started:
1. Install 7z

    ![7z setup screen](raw/master/docs/img/7zinstall.png "7z setup screen")

2. Add PowerShell-ISE to server (this is not mandatory, but useful when you want to review or edit the script)

    Through Windows Server Feature Manager

    ![adding ise in windows server feature setup](raw/master/docs/img/iseinstall.png "adding ise in windows server feature setup")

    or using PowerShell to enable ISE directly

    ![adding ise from command line](raw/master/docs/img/iseinstall02.png "adding ise from command line")

3. Ensure `ExecutionPolicy` allows unsigned local scripts

    ![setting ExecutionPolicy](raw/master/docs/img/setExecutionPolicy.png "setting ExecutionPolicy")

    **Note**: `RemoteSigned` will allow local scripts to be unsigned, but require remote scripts to be signed. Before changing the execution policy - ensure it was not set to `Unrestricted` by someone else. Below screenshot shows the `ExecutionPolicy` was set to `Unrestricted` in which case we should **not** modify the setting.

    ![note ExecutionPolicy](raw/master/docs/img/setExecutionPolicyNote.png "note ExecutionPolicy")

    To set the `ExectionPolicy` run the `Set-ExecutionPolicy` cmdlet with `RemoteSigned` as the new value:

```
#!powershell
Set-ExecutionPolicy RemoteSigned
```

4. Create a Windows account as a backup operator for the Auto backup script. Only provide the minimum permissions required for the script:

    ![adding windows account through server manager](raw/master/docs/img/createsvcSunBak.png "adding windows account through server manager")

    1. This account should be able to run SunSystems (should be member of SUClients local group)
    2. This account should be able to run scripts on schedule (should be a member of Backup Operators local group)
    3. This account password should **not expire** and **be strong**

5. Create a SunSystems account with windows authentication enabled and ISM permissions:

    1. General

        ![adding sunsystems account through user manager - general](raw/master/docs/img/createBAK01.png "adding sunsystems account through user manager - general")

    2. SunSystems 4 settings

        ![adding sunsystems account through user manager - sun4](raw/master/docs/img/createBAK02.png "adding sunsystems account through user manager - sun4")

    3. Windows Authentication

        ![adding sunsystems account through user manager - win auth](raw/master/docs/img/createBAK03.png "adding sunsystems account through user manager - win auth")

6. Record a SunSystems macro called "FB" for the File Backup of all databases requiring a backup

    **Note**: `SunBackup.ps1` expects the macro name to be `FB` in the `STANDARD.MDF`.

    ![expected macro name in MDF](raw/master/docs/img/expectedMDF.png "expected macro name in MDF")

7. Once the macro has been recorded, it is required to **edit** the macro, adding the Backup user SUN Operator ID and Password, below the macro name but before any SunSystems commands. This is required to run scripts from command line even with Windows Authentication enabled on the account. 

    **Note**: Due to the Hilton Policy, after 90 days the password will be expired and will need to be updated. The script will notify relevant parties when the backups are no longer working.

    ![editing sunsystems macro definition file, adding operator ID & password](raw/master/docs/img/editMDF.png "editing sunsystems macro definition file, adding operator ID & password")

8. Copy the latest release of the [SunBackup.ps1](raw/master/SunBackup.ps1) script to the SunSystems server

9. Edit the `SunBackup.ps1` script:

    ![editing SunBackup.ps1 powershell script](raw/maser/docs/img/updateScript.png "editing SunBackup.ps1 powershell script")

    Ensure the following 3 points:

    1. The script should point to the correct FileSystems paths, **communicate these paths to ISM** to ensure tape backups or network mirrored folders exist

    2. Update the e-mail contacts to be notified in case SunSystems backup files are out of date.

        **Note** `@(..)` in powershell is used to formally create an array for 1 or multiple addresses, but the emails could just be a comma separated list of strings (that should work too, but has not been tested)

        **Note** some ISM create an `<INNCODE>_IT@Hilton.com` alias for their property to ensure future emails will always reach the correct person (in case ISM moved to another property of left the company), **please verify with ISM if such alias exists**

10. Test the `SunBackup.ps1` script by running it with PowerShell. For example using the standard windows command shell:

    ![testing SunBackup.ps1](raw/master/docs/img/testScript.png "testing SunBackup.ps1")


