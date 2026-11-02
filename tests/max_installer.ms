/* Run in a disposable Max process: 3dsmax.exe -q -silent -U MAXScript <this file>. */
(
    local root = (dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName())) + "..\\")
    local sandbox = root + ".build\\installer-smoke"
    (dotNetClass "System.IO.Directory").CreateDirectory sandbox
    local logFile = createFile (sandbox + "\\result.txt")
    global conquerInstallerMessages = #()
    global captureInstallMessage
    fn captureInstallMessage text title:"" = (append conquerInstallerMessages text; true)
    try
    (
        local original = (dotNetClass "System.IO.File").ReadAllText (root + "ConquerMaxChecker\\安装到MAX启动.ms")
        local body = substituteString original "messageBox" "captureInstallMessage"
        body = substituteString body "try(installerPath = getSourceFileName())" ("try(installerPath = @\"" + root + "ConquerMaxChecker\\安装到MAX启动.ms\")")
        body = substituteString body "getDir #userScripts" ("@\"" + sandbox + "\\scripts\"")
        body = substituteString body "getDir #userStartupScripts" ("@\"" + sandbox + "\\startup\"")
        body = substituteString body "((dotNetClass \"System.Environment\").GetEnvironmentVariable \"LOCALAPPDATA\")" ("@\"" + sandbox + "\"")
        body = substituteString body "try(fileIn macroPath)catch()" "true"
        execute body
        if conquerInstallerMessages.count != 1 do throw "Expected one result message"
        if not matchPattern conquerInstallerMessages[1] pattern:"安装完成*" do throw conquerInstallerMessages[1]
        local target = sandbox + "\\scripts\\ConquerMaxChecker"
        if not doesFileExist (target + "\\ConquerAssetTool.exe") do throw "Missing installed EXE"
        if not doesFileExist (target + "\\_runtime\\python312.dll") do throw "Missing installed runtime"
        if not doesFileExist (sandbox + "\\startup\\ConquerMaxChecker_AutoLoad.ms") do throw "Missing startup loader"
        format "INSTALL_SUCCESS_OK\n" to:logFile

        -- Missing source must stop before creating a new installation directory.
        conquerInstallerMessages = #()
        local missing = substituteString body "ConquerAssetTool.exe" "missing-asset-tool.exe"
        missing = substituteString missing "\\scripts\"" "\\missing-source-target\""
        execute missing
        if conquerInstallerMessages.count != 1 do throw "Expected one missing-source message"
        if not matchPattern conquerInstallerMessages[1] pattern:"安装未开始*missing-asset-tool.exe*" do throw conquerInstallerMessages[1]
        if doesDirectoryExist (sandbox + "\\missing-source-target\\ConquerMaxChecker") do throw "Missing-source preflight changed target"
        format "MISSING_SOURCE_OK\n" to:logFile

        -- A locked target must preserve the .NET exception and exact filename.
        local lockedFile = target + "\\ConquerAssetTool.exe"
        local lockStream = (dotNetClass "System.IO.File").Open lockedFile (dotNetClass "System.IO.FileMode").Open (dotNetClass "System.IO.FileAccess").Read (dotNetClass "System.IO.FileShare").None
        conquerInstallerMessages = #()
        local failed = false
        try(execute body)catch(failed = true)
        lockStream.Close()
        if failed do throw "Installer failed to handle locked EXE"
        if conquerInstallerMessages.count != 1 do throw "Expected one locked-file message"
        if not matchPattern conquerInstallerMessages[1] pattern:"安装失败*ConquerAssetTool.exe*错误*" do throw conquerInstallerMessages[1]
        format "LOCKED_TARGET_OK\n" to:logFile

        -- An existing but locked loader must report failure rather than success.
        local loader = sandbox + "\\startup\\ConquerMaxChecker_AutoLoad.ms"
        local previousLoader = (dotNetClass "System.IO.File").ReadAllText loader
        lockStream = (dotNetClass "System.IO.File").Open loader (dotNetClass "System.IO.FileMode").Open (dotNetClass "System.IO.FileAccess").Read (dotNetClass "System.IO.FileShare").None
        conquerInstallerMessages = #()
        failed = false
        try(execute body)catch(failed = true)
        lockStream.Close()
        if failed do throw "Installer failed to handle locked startup loader"
        if conquerInstallerMessages.count != 1 do throw "Expected one startup failure message"
        if not matchPattern conquerInstallerMessages[1] pattern:"安装失败*ConquerMaxChecker_AutoLoad.ms*错误*" do throw conquerInstallerMessages[1]
        if ((dotNetClass "System.IO.File").ReadAllText loader) != previousLoader do throw "Existing loader changed on failed update"
        format "LOCKED_LOADER_OK\n" to:logFile

        -- Exercise real Max user folders, including their actual ACLs.
        conquerInstallerMessages = #()
        local actual = substituteString original "messageBox" "captureInstallMessage"
        actual = substituteString actual "try(installerPath = getSourceFileName())" ("try(installerPath = @\"" + root + "ConquerMaxChecker\\安装到MAX启动.ms\")")
        actual = substituteString actual "try(fileIn macroPath)catch()" "true"
        execute actual
        if conquerInstallerMessages.count != 1 do throw "Expected one real installation message"
        if not matchPattern conquerInstallerMessages[1] pattern:"安装完成*" do throw conquerInstallerMessages[1]
        local actualLoader = (getDir #userStartupScripts) + "\\ConquerMaxChecker_AutoLoad.ms"
        if ((dotNetClass "System.IO.File").ReadAllText actualLoader) != previousLoader do throw "Real startup loader differs from package"
        format "REAL_USER_INSTALL_OK\nPASS\n" to:logFile
    )
    catch(format "FAIL: %\n" (getCurrentException() as string) to:logFile)
    close logFile
    quitMax #noPrompt
)
