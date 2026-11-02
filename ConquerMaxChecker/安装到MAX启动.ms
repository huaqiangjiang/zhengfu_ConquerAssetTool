/*
    征服MAX模型检查器 - 安装到 3ds Max 启动加载
    用法：把本文件拖入 3ds Max。脚本会先把完整插件同步到 Max 用户脚本目录，
    然后设置启动加载器；之后每次打开 Max 都会加载同步后的版本。
*/

(
    local installerPath = ""
    local packageFolder = ""
    local installedFolder = ""
    local macroPath = ""
    local startupFolder = ""
    local loaderPath = ""
    local loaderSource = ""
    local copyOk = true
    local copyFailures = #()
    local failedText = ""
    local copyDetails = #()
    local requiredFiles = #("ConquerMaxChecker.mcr", "ConquerMaxChecker.ms", "ConquerMaxChecker_AutoLoad.ms", "ConquerAssetTool.exe", "PhotoshopRefine.ps1", "PS精修使用说明.txt", "_runtime\\python312.dll", "_runtime\\base_library.zip")
    local missingFiles = #()
    local diagnosticPath = ""

    fn copyFileReplace sourceFile targetFile details =
    (
        if sourceFile == "" or not doesFileExist sourceFile then
        (
            append details ("源文件不存在：" + sourceFile)
            return false
        )
        if toLower sourceFile == toLower targetFile then return true
        try
        (
            (dotNetClass "System.IO.File").Copy sourceFile targetFile true
            doesFileExist targetFile
        )
        catch
        (
            append details ("源：" + sourceFile + "\n目标：" + targetFile + "\n错误：" + (getCurrentException() as string))
            false
        )
    )

    fn copyFolderRecursive sourceFolder targetFolder details =
    (
        local files = #()
        local folders = #()
        local sourceFile = ""
        local targetFile = ""
        local sourceSubFolder = ""
        local targetSubFolder = ""
        local cleanSubFolder = ""
        local subFolderName = ""
        local ok = true
        local copied = false

        if sourceFolder == "" or not doesDirectoryExist sourceFolder then
        (
            append details ("源目录不存在：" + sourceFolder)
            return false
        )
        if not doesDirectoryExist targetFolder do
            try(makeDir targetFolder)catch()
        if not doesDirectoryExist targetFolder then
        (
            append details ("无法创建目标目录：" + targetFolder)
            return false
        )

        try(files = getFiles (sourceFolder + "\\*"))catch(append details ("无法读取目录：" + sourceFolder); ok = false)
        for sourceFile in files do
        (
            targetFile = targetFolder + "\\" + (filenameFromPath sourceFile)
            try
            (
                copied = copyFileReplace sourceFile targetFile details
                if not copied do ok = false
            )
            catch(append details (getCurrentException() as string); ok = false)
        )

        try(folders = getDirectories (sourceFolder + "\\*"))catch(append details ("无法读取子目录：" + sourceFolder); ok = false)
        for sourceSubFolder in folders do
        (
            cleanSubFolder = sourceSubFolder
            while cleanSubFolder.count > 3 and ((substring cleanSubFolder cleanSubFolder.count 1) == "\\" or (substring cleanSubFolder cleanSubFolder.count 1) == "/") do
                cleanSubFolder = substring cleanSubFolder 1 (cleanSubFolder.count - 1)
            subFolderName = filenameFromPath cleanSubFolder
            targetSubFolder = targetFolder + "\\" + subFolderName
            if not (copyFolderRecursive sourceSubFolder targetSubFolder details) do
                ok = false
        )
        ok
    )

    try(installerPath = getSourceFileName())catch(installerPath = "")
    if installerPath != "" do packageFolder = getFilenamePath installerPath
    macroPath = packageFolder + "ConquerMaxChecker.mcr"
    loaderSource = packageFolder + "ConquerMaxChecker_AutoLoad.ms"
    try(installedFolder = (getDir #userScripts) + "\\ConquerMaxChecker")catch(installedFolder = "")

    try(startupFolder = getDir #userStartupScripts)catch(startupFolder = "")
    if startupFolder == "" do try(startupFolder = getDir #startupScripts)catch(startupFolder = "")
    for requiredFile in requiredFiles where not doesFileExist (packageFolder + requiredFile) do append missingFiles requiredFile

    if packageFolder == "" or missingFiles.count > 0 then
    (
        for missingFile in missingFiles do failedText += missingFile + "\n"
        messageBox ("安装未开始：插件源文件缺失。\n\n缺失项目：\n" + failedText + "\n源目录：\n" + packageFolder + "\n\n请获取完整插件包，保留 _runtime 目录。若 EXE 解压后消失，请检查 Windows 安全中心的保护历史记录。") title:"征服MAX模型检查器"
    )
    else if startupFolder == "" or installedFolder == "" then
    (
        messageBox "安装失败：无法取得 3ds Max 用户脚本或启动脚本目录。" title:"征服MAX模型检查器"
    )
    else
    (
        if not doesDirectoryExist installedFolder do try(makeDir installedFolder)catch()
        if not doesDirectoryExist installedFolder then
        (
            messageBox ("安装失败：无法创建插件目录。\n\n目标路径：\n" + installedFolder) title:"征服MAX模型检查器"
        )
        else
        (
            /*
                只同步插件运行必需的文件和目录，避免把整合包 ZIP、
                说明文件等无关内容复制到 Max 用户脚本目录。
            */
            if not (copyFileReplace (packageFolder + "ConquerMaxChecker.mcr") (installedFolder + "\\ConquerMaxChecker.mcr") copyDetails) do
            (
                copyOk = false
                append copyFailures "ConquerMaxChecker.mcr"
            )
            if not (copyFileReplace (packageFolder + "ConquerMaxChecker.ms") (installedFolder + "\\ConquerMaxChecker.ms") copyDetails) do
            (
                copyOk = false
                append copyFailures "ConquerMaxChecker.ms"
            )
            if not (copyFolderRecursive (packageFolder + "_runtime") (installedFolder + "\\_runtime") copyDetails) do
            (
                copyOk = false
                append copyFailures "_runtime"
            )
            if not (copyFileReplace (packageFolder + "ConquerAssetTool.exe") (installedFolder + "\\ConquerAssetTool.exe") copyDetails) do
            (
                copyOk = false
                append copyFailures "ConquerAssetTool.exe"
            )
            for requiredFile in #("PhotoshopRefine.ps1", "PS精修使用说明.txt") do
            (
                if not (copyFileReplace (packageFolder + requiredFile) (installedFolder + "\\" + requiredFile) copyDetails) do
                (
                    copyOk = false
                    append copyFailures requiredFile
                )
            )
            /* 目录构建需要 _runtime；旧 _internal 不参与运行。 */
            if doesDirectoryExist (packageFolder + "compressonator") do
                if not (copyFolderRecursive (packageFolder + "compressonator") (installedFolder + "\\compressonator") copyDetails) do
                (
                    copyOk = false
                    append copyFailures "compressonator"
                )

            if not copyOk then
            (
                failedText = ""
                for failedFile in copyFailures do
                    failedText += failedFile + "\n"
                for detail in copyDetails do failedText += "\n" + detail + "\n"
                try
                (
                    diagnosticPath = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\reports"
                    (dotNetClass "System.IO.Directory").CreateDirectory diagnosticPath
                    diagnosticPath += "\\install-error.txt"
                    (dotNetClass "System.IO.File").WriteAllText diagnosticPath failedText (dotNetClass "System.Text.Encoding").UTF8
                )catch(diagnosticPath = "日志写入失败")
                messageBox ("安装失败：插件文件同步不完整。\n\n" + failedText + "\n请根据具体错误检查文件占用、目录权限或安全软件保护历史。\n\n诊断日志：\n" + diagnosticPath) title:"征服MAX模型检查器"
            )
            else
            (
        loaderPath = startupFolder + "\\ConquerMaxChecker_AutoLoad.ms"
        local loaderOk = false
        try
        (
            (dotNetClass "System.IO.Directory").CreateDirectory startupFolder
            loaderOk = copyFileReplace loaderSource loaderPath copyDetails
        )
        catch(append copyDetails ("启动目录：" + startupFolder + "\n错误：" + (getCurrentException() as string)))
        if not loaderOk then
        (
            failedText = ""
            for detail in copyDetails do failedText += detail + "\n\n"
            try
            (
                diagnosticPath = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\reports"
                (dotNetClass "System.IO.Directory").CreateDirectory diagnosticPath
                diagnosticPath += "\\install-error.txt"
                (dotNetClass "System.IO.File").WriteAllText diagnosticPath failedText (dotNetClass "System.Text.Encoding").UTF8
            )catch(diagnosticPath = "日志写入失败")
            messageBox ("安装失败：无法写入 Max 启动加载器。\n\n" + failedText + "请根据具体错误检查启动目录写入权限或文件占用。\n\n目标路径：\n" + loaderPath + "\n\n诊断日志：\n" + diagnosticPath) title:"征服MAX模型检查器"
        )
        else
        (
            macroPath = installedFolder + "\\ConquerMaxChecker.mcr"
            try(fileIn macroPath)catch()
            messageBox ("安装完成，已同步最新插件文件。\n\n以后每次打开 3ds Max 都会自动加载征服MAX模型检查器。\n\n插件目录：\n" + installedFolder + "\n\n启动加载器：\n" + loaderPath) title:"征服MAX模型检查器"
        )
            )
        )
    )
)
