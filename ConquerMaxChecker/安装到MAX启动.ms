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

    fn copyFileReplace sourceFile targetFile =
    (
        if sourceFile == "" or not doesFileExist sourceFile then return false
        if toLower sourceFile == toLower targetFile then return true
        try
        (
            (dotNetClass "System.IO.File").Copy sourceFile targetFile true
            doesFileExist targetFile
        )catch(false)
    )

    fn copyFolderRecursive sourceFolder targetFolder =
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

        if sourceFolder == "" or not doesDirectoryExist sourceFolder then return false
        if not doesDirectoryExist targetFolder do
            try(makeDir targetFolder)catch()
        if not doesDirectoryExist targetFolder then return false

        try(files = getFiles (sourceFolder + "\\*"))catch(files = #())
        for sourceFile in files do
        (
            targetFile = targetFolder + "\\" + (filenameFromPath sourceFile)
            try
            (
                copied = copyFileReplace sourceFile targetFile
                if not copied do ok = false
            )
            catch(ok = false)
        )

        try(folders = getDirectories (sourceFolder + "\\*"))catch(folders = #())
        for sourceSubFolder in folders do
        (
            cleanSubFolder = sourceSubFolder
            while cleanSubFolder.count > 3 and ((substring cleanSubFolder cleanSubFolder.count 1) == "\\" or (substring cleanSubFolder cleanSubFolder.count 1) == "/") do
                cleanSubFolder = substring cleanSubFolder 1 (cleanSubFolder.count - 1)
            subFolderName = filenameFromPath cleanSubFolder
            targetSubFolder = targetFolder + "\\" + subFolderName
            if not (copyFolderRecursive sourceSubFolder targetSubFolder) do
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

    if packageFolder == "" or not doesFileExist macroPath or not doesFileExist (packageFolder + "ConquerMaxChecker.ms") then
    (
        messageBox "安装失败：没有找到完整的插件文件。请确认 ConquerMaxChecker.mcr 和 ConquerMaxChecker.ms 与本安装脚本在同一目录。" title:"征服MAX模型检查器"
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
            if not (copyFileReplace (packageFolder + "ConquerMaxChecker.mcr") (installedFolder + "\\ConquerMaxChecker.mcr")) do
            (
                copyOk = false
                append copyFailures "ConquerMaxChecker.mcr"
            )
            if not (copyFileReplace (packageFolder + "ConquerMaxChecker.ms") (installedFolder + "\\ConquerMaxChecker.ms")) do
            (
                copyOk = false
                append copyFailures "ConquerMaxChecker.ms"
            )
            if not (copyFileReplace (packageFolder + "ConquerAssetTool.exe") (installedFolder + "\\ConquerAssetTool.exe")) do
            (
                copyOk = false
                append copyFailures "ConquerAssetTool.exe"
            )
            for requiredFile in #("PhotoshopMIP1.ps1", "PS精修使用说明.txt") do
            (
                if not (copyFileReplace (packageFolder + requiredFile) (installedFolder + "\\" + requiredFile)) do
                (
                    copyOk = false
                    append copyFailures requiredFile
                )
            )
            /* v0.2.0 EXE 已包含运行环境，不再复制旧 _internal。 */
            if doesDirectoryExist (packageFolder + "compressonator") do
                if not (copyFolderRecursive (packageFolder + "compressonator") (installedFolder + "\\compressonator")) do
                (
                    copyOk = false
                    append copyFailures "compressonator"
                )

            if not copyOk then
            (
                failedText = ""
                for failedFile in copyFailures do
                    failedText += failedFile + "\n"
                messageBox ("安装失败：插件文件同步不完整。\n\n失败项目：\n" + failedText + "\n请确认 3ds Max 不是以管理员身份运行，或检查用户脚本目录权限。\n\n目标目录：\n" + installedFolder) title:"征服MAX模型检查器"
            )
            else
            (
        if not doesDirectoryExist startupFolder do makeDir startupFolder
        loaderPath = startupFolder + "\\ConquerMaxChecker_AutoLoad.ms"
        if doesFileExist loaderPath do try(deleteFile loaderPath)catch()
        if doesFileExist loaderSource do
            try(copyFile loaderSource loaderPath)catch()
        if not doesFileExist loaderPath then
        (
            messageBox ("安装失败：无法写入 Max 启动脚本目录。\n\n请关闭“以管理员身份运行”的 Max，正常启动后再运行本文件。\n\n目标路径：\n" + loaderPath) title:"征服MAX模型检查器"
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
