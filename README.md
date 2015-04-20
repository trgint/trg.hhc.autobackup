#Hilton Automated SunSystems backup Powershell script

##Getting Started:
1. Install 7z

    ![7z setup screen](raw/master/docs/img/7zinstall.png "7z setup screen")

2. Add PowerShell-ISE to server 

    (this is not mandatory, but useful when you want to review the script)

    ![adding ise in windows server feature setup](raw/master/docs/img/iseinstall.png "adding ise in windows server feature setup")

    or using PowerShell to enable ISE directly

    ![adding ise from command line](raw/master/docs/img/iseinstall02.png "adding ise from command line")

3. Ensure `ExecutionPolicy` allows unsigned local scripts

    ![setting ExecutionPolicy](raw/master/docs/img/setExecutionPolicy.png "setting ExecutionPolicy")

    **Note**: `RemoteSigned` will allow local scripts to be unsigned, but require remote scripts to be signed. Before changing the execution policy - ensure it was not set to `Unrestricted` by someone else. Below screenshot shows the `ExecutionPolicy` was set to `Unrestricted` in which case we should **not** modify the setting.

    ![note ExecutionPolicy](raw/master/docs/img/setExecutionPolicyNote.png "note ExecutionPolicy")

    To set the `ExectionPolicy` run the `Set-ExecutionPolicy` cmdlet with `RemoteSigned` as the new value:

    ```
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
