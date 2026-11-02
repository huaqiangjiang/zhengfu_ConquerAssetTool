/*
Conquer MAX Checker for 3ds Max 2015

打开生产 .max 文件后运行本脚本。基础体为可选的观察对象，不参与生产模型检查。
检查结果分为“通过”和“不通过”两栏；脚本错误也会显示在“不通过”栏。
*/

global ConquerMaxChecker
global ConquerMaxCheckerScriptFile
global ConquerMaxCheckerScriptVersion
ConquerMaxCheckerScriptFile = ""
ConquerMaxCheckerScriptVersion = "2026-11-02-v0.2.9-runtime"
try(ConquerMaxCheckerScriptFile = getSourceFileName())catch()

struct ConquerCheckItem
(
    status,
    category,
    target,
    detail,
    suggestion
)

struct ConquerMaxCheckerStruct
(
    report = #(),
    baseFile = undefined,
    importedBaseNodes = #(),
    importedBaseMaterials = #(),
    lastError = "",
    rejectedPSDSourcePaths = #(),
    silentSuccessMessages = false,
    psRefine = true,
    psVersion = "auto",
    busy = false,
    cancelRequested = false,
    selectedOnly = false,
    collectingFixErrors = false,
    fixErrors = #(),
    lastBackup = "",
    exportLogBaseline = #(),
    lastConversionText = "",

    externalRoot = "",
    externalRootManual = false,
    externalTool = "",
    externalOutput = "",

    -- Max 2015 resolves names while compiling; predeclare methods used before their definition.
    fn commitOutput = (),
    fn newRunId = (),
    fn isImportedBaseNode = (),
    fn refreshImportedBaseState = (),
    fn isProductionNode = (),
    fn addRuntimeError = (),
    fn baseStatusText = (),
    fn importStatusText = (),
    fn asText = (),
    fn exceptionText = (),
    fn quotePath = (),
    fn trimTrailingPathSeparators = (),
    fn currentMaxFullPath = (),
    fn scriptFolder = (),
    fn desktopFolder = (),
    fn findExternalTool = (),
    fn findPython = (),
    fn externalReportFolder = (),
    fn runExternalProcess = (),
    fn beginFix = (),
    fn endFix = (),
    fn appendFixErrors = (),
    fn saveCurrentScene = (),
    fn runExternalCheck = (),
    fn runExternalHierarchyFix = (),
    fn runDDSDetection = (),
    fn runDDSConversion = (),
    fn runPNGConversion = (),
    fn runTextureConversion = (),
    fn externalCsvPath = (),
    fn externalJsonPath = (),
    fn externalTextPath = (),
    fn externalMaxDisplayPath = (),
    fn readUtf8Lines = (),
    fn stripUtf8Bom = (),
    fn readExternalText = (),
    fn openExternalText = (),
    fn hasDirectMaxFiles = (),
    fn hasResourceSiblingFolders = (),
    fn parentFolderOf = (),
    fn isDesktopOrDriveRootFolder = (),
    fn findResourceMaxFolder = (),
    fn validateExternalRoot = (),
    fn resourceRootFromMaxFile = (),
    fn currentMaxResourceRoot = (),
    fn currentMaxPlacementError = (),
    fn syncExternalRootToCurrentMax = (),
    fn openMaxParentFolder = (),
    fn saveSceneToMaxFolder = (),
    fn readExternalCsv = (),
    fn parseCsvLine = (),
    fn compactExternalCsv = (),
    fn compactExternalText = (),
    fn compactExternalDisplay = (),
    fn externalReportHasBlockingIssues = (),
    fn openExternalReport = (),
    fn makeDesktopPlan = (),
    fn add = (),
    fn resetReport = (),
    fn csvEscape = (),
    fn getGeometryNodes = (),
    fn getMaterialNodes = (),
    fn collectBitmapTexturesRecursive = (),
    fn materialNameKey = (),
    fn bitmapFilenameStemKey = (),
    fn stripLooseNamePrefix = (),
    fn looseTextureNameMatch = (),
    fn bitmapTexturesFromMatchingSceneMaterials = (),
    fn bitmapTexturesFromKnownFilesMatchingMaterialNames = (),
    fn getBodyNodes = (),
    fn isGroupedNode = (),
    fn groupedNodes = (),
    fn getNodeDims = (),
    fn importBaseBody = (),
    fn faceArea = (),
    fn meshReport = (),
    fn countNgons = (),
    fn transformIsClean = (),
    fn likelyBoneNodes = (),
    fn animatedNodes = (),
    fn bitmapTextures = (),
    fn bitmapTexturesFromMaterialList = (),
    fn allKnownBitmapTextures = (),
    fn knownBitmapTexturesMatchingProductionNames = (),
    fn ddsConversionBitmapTextures = (),
    fn productionMaterials = (),
    fn baseMaterials = (),
    fn isBaseMaterial = (),
    fn sameColor = (),
    fn checkUnits = (),
    fn checkBaseImport = (),
    fn checkGeometry = (),
    fn checkSceneExtras = (),
    fn bitmapCoordsOk = (),
    fn diffuseBitmapOutputOk = (),
    fn opacityBitmapOutputOk = (),
    fn resolvedTexturePathForBitmap = (),
    fn readBinaryFileBytes = (),
    fn tgaAlphaState = (),
    fn tgaFileHasAlpha = (),
    fn tgaFileAlphaReadable = (),
    fn bitmapFilesMatch = (),
    fn isDefaultScanlineRendererValue = (),
    fn isBitmapTex = (),
    fn checkMaterials = (),
    fn checkEnvironment = (),
    fn checkRenderAndGammaSettings = (),
    fn fixEnvironment = (),
    fn setBackfaceCull = (),
    fn fixDisplaySettings = (),
    fn fixGammaSettings = (),
    fn fixProductRenderMode = (),
    fn fixRenderSettings = (),
    fn fixUnits = (),
    fn fixNormalsAndReset = (),
    fn collectMaterialTree = (),
    fn productionMaterialTree = (),
    fn setupBitmapCoords = (),
    fn setupDiffuseBitmap = (),
    fn setupOpacityBitmap = (),
    fn materialIsPlainStandard = (),
    fn materialHasDiffuseBitmap = (),
    fn preferredPlainMaterialSource = (),
    fn standardMaterialFromSource = (),
    fn normalizeProductionNodeMaterials = (),
    fn materialBitmapTextures = (),
    fn collectTextureDirsFromMaps = (),
    fn pruneUnusedTextureSearchPaths = (),
    fn normalizeProductionMaterialNames = (),
    fn normalizeProductionTextureExtensionsToTga = (),
    fn stripProductionTexturePaths = (),
    fn fixTexturePathsOnly = (),
    fn checkTexturePathsRemoved = (),
    fn fixMaterialSettings = (),
    fn clearMaterialEditorSlots = (),
    fn syncMaterialEditorSlots = (),
    fn collapseShellMaterialTree = (),
    fn collapseShellMaterials = (),
    fn finalResetTransformAndCollapse = (),
    fn fixMaterialsAndTextures = (),
    fn fixGeometry = (),
    fn removeImportedBaseBody = (),
    fn fixSceneExtras = (),
    fn runEnvironmentCheck = (),
    fn runModelCheck = (),
    fn runMaterialCheck = (),
    fn fixEnvironmentOnly = (),
    fn fixModelOnly = (),
    fn fixMaterialOnly = (),
    fn autoFix = (),
    fn runAll = (),
    fn compactShortText = (),
    fn compactTargetText = (),
    fn compactReportText = (),
    fn reportPassText = (),
    fn reportIssueText = (),
    fn textureFileStemEndsWithF = (),
    fn interfaceNodeExcludedByTexture = (),
    fn textureStemForNode = (),
    fn safeC3Stem = (),
    fn c3ResourceRoot = (),
    fn outputResourceRoot = (),
    fn currentMaxStem = (),
    fn getNodesWorldBounds = (),
    fn getEvaluatedNodesWorldBounds = (),
    fn findTextureFileByLeaf = (),
    fn resolveTextureSource = (),
    fn nonDDSProductionTextureRefs = (),
    fn referencedDDSSourcePaths = (),
    fn directDDSReferenceCount = (),
    fn ddsFolderForSource = (),
    fn relinkProductionTexturesToDDS = (),
    fn uniqueC3Path = (),
    fn cleanupC3ExportDocs = (),
    fn c3PathForExport = (),
    fn restoreC3ExportTimeRange = (),
    fn copyC3TexturesForNode = (),
    fn makeRenderPreviewSet = (),
    fn moveRenderPreviewSetToCenter = (),
    fn makeRenderOutputPath = (),
    fn makeInterfaceRenderOutputFolder = (),
    fn cleanupRenderTemporaryNodes = (),
    fn renderPreviewImage = (),
    fn renderInterfaceUI = (),
    fn exportC3Objects = (),
    fn externalPassText = (),
    fn externalIssueText = (),

    fn commitOutput source target =
    (
        if not doesFileExist source or getFileSize source <= 0 do throw "没有有效的新输出文件。"
        if doesFileExist target then
        (
            local previous = target + ".ConquerPrevious_" + (newRunId()) + ".tmp"
            (dotNetClass "System.IO.File").Replace source target previous
            try(deleteFile previous)catch()
        )
        else (dotNetClass "System.IO.File").Move source target
        true
    ),

    fn newRunId =
    (
        local value = (dotNetClass "System.Guid").NewGuid()
        value.ToString()
    ),

    fn isImportedBaseNode n =
    (
        isValidNode n and ((findItem importedBaseNodes n) > 0 or matchPattern n.name pattern:"baseObs_*" ignoreCase:true)
    ),

    fn refreshImportedBaseState =
    (
        local foundNodes = #()
        local foundMaterials = #()
        local sceneNodes = #()
        local sceneMaterials = #()

        try(sceneNodes = objects as array)catch(sceneNodes = #())
        for n in sceneNodes where isValidNode n do
        (
            local nodeName = ""
            try(nodeName = toLower (n.name as string))catch(nodeName = "")
            if nodeName != "" and matchPattern nodeName pattern:"baseobs_*" ignoreCase:true do
                append foundNodes n
        )
        importedBaseNodes = makeUniqueArray foundNodes

        try(sceneMaterials = scenematerials as array)catch(sceneMaterials = #())
        for m in sceneMaterials where m != undefined do
        (
            local materialName = ""
            try(materialName = toLower (m.name as string))catch(materialName = "")
            if materialName != "" and matchPattern materialName pattern:"baseobsmat_*" ignoreCase:true do
                append foundMaterials m
        )
        for n in importedBaseNodes where isValidNode n do
        (
            local nodeMaterial = undefined
            try(nodeMaterial = n.material)catch(nodeMaterial = undefined)
            if nodeMaterial != undefined do append foundMaterials nodeMaterial
        )
        importedBaseMaterials = makeUniqueArray foundMaterials
        importedBaseNodes.count > 0
    ),

    fn isProductionNode n =
    (
        isValidNode n and not (isImportedBaseNode n) and
        not (matchPattern n.name pattern:"ConquerRenderTmp_*" ignoreCase:true) and
        not (matchPattern n.name pattern:"ConquerInterfaceTmp_*" ignoreCase:true) and
        (getUserProp n "ConquerReference") != true
    ),

    fn addRuntimeError section detail =
    (
        local item = ConquerCheckItem status:"不通过" category:"报错" target:(section as string) detail:(detail as string) suggestion:"查看原因后重试；修改前备份可用于恢复。"
        append report item
        if collectingFixErrors do append fixErrors item
    ),

    fn baseStatusText =
    (
        try(refreshImportedBaseState())catch()
        if importedBaseNodes.count > 0 then
            "基础体状态：已导入，保留在场景中用于观察；对象数=" + (importedBaseNodes.count as string)
        else if baseFile != undefined then
            "基础体状态：已移除"
        else
            "基础体状态：未导入"
    ),

    fn importStatusText =
    (
        if lastError == "" then "基础体状态：导入失败" else "基础体状态：导入失败；" + lastError
    ),

    fn asText v =
    (
        if v == undefined then "" else (v as string)
    ),

    fn exceptionText fallback =
    (
        local text = fallback
        try(text = (getCurrentException() as string))catch()
        text
    ),

    fn quotePath value =
    (
        "\"" + (asText value) + "\""
    ),

    fn trimTrailingPathSeparators value =
    (
        local result = asText value
        while result.count > 3 and ((substring result result.count 1) == "\\" or (substring result result.count 1) == "/") do
            result = substring result 1 (result.count - 1)
        result
    ),

    fn currentMaxFullPath =
    (
        if maxFilePath == undefined or maxFileName == undefined or maxFileName == "" then ""
        else maxFilePath + maxFileName
    ),

    fn scriptFolder =
    (
        local scriptFile = ""
        try(scriptFile = ConquerMaxCheckerScriptFile)catch()
        if scriptFile == "" do try(scriptFile = getSourceFileName())catch()
        if scriptFile != "" then getFilenamePath scriptFile else getDir #scripts
    ),

    fn desktopFolder =
    (
        local profile = ""
        local oneDrive = ""
        local desktop = ""
        local regClass = undefined
        local regKey = undefined
        local regDesktop = undefined

        try(profile = (dotNetClass "System.Environment").GetEnvironmentVariable "USERPROFILE")catch()
        try(oneDrive = (dotNetClass "System.Environment").GetEnvironmentVariable "OneDrive")catch()

        /*
            优先读取 Windows 当前登记的真实桌面位置。
            “Desktop”或“桌面”只是资源管理器显示名，不参与文件判断。
        */
        try
        (
            regClass = dotNetClass "Microsoft.Win32.Registry"
            regKey = regClass.CurrentUser.OpenSubKey "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders"
            regDesktop = regKey.GetValue "Desktop"
            if regDesktop != undefined do
            (
                desktop = regDesktop as string
                if profile != "" do desktop = substituteString desktop "%USERPROFILE%" profile
                if oneDrive != "" do desktop = substituteString desktop "%OneDrive%" oneDrive
                if doesDirectoryExist desktop then return desktop
            )
        )
        catch()

        if profile != "" do
        (
            desktop = profile + "\\Desktop"
            if doesDirectoryExist desktop then return desktop
            desktop = profile + "\\桌面"
            if doesDirectoryExist desktop then return desktop
        )

        if oneDrive != "" do
        (
            desktop = oneDrive + "\\Desktop"
            if doesDirectoryExist desktop then return desktop
            desktop = oneDrive + "\\桌面"
            if doesDirectoryExist desktop then return desktop
        )

        ""
    ),

    fn findExternalTool =
    (
        local exeFile = scriptFolder() + "ConquerAssetTool.exe"
        if doesFileExist exeFile then exeFile else undefined
    ),

    fn findPython = (undefined),

    fn runExternalProcess exePath arguments logPath =
    (
        local proc = undefined
        try
        (
            local info = dotNetObject "System.Diagnostics.ProcessStartInfo"
            if matchPattern (toLower exePath) pattern:"*.py" then
            (
                info.FileName = findPython()
                info.Arguments = (quotePath exePath) + " " + arguments
            )
            else
            (
                info.FileName = exePath
                info.Arguments = arguments
            )
            info.WorkingDirectory = scriptFolder()
            info.UseShellExecute = false
            info.CreateNoWindow = true
            info.RedirectStandardOutput = true
            info.RedirectStandardError = true
            info.StandardOutputEncoding = (dotNetClass "System.Text.Encoding").UTF8
            info.StandardErrorEncoding = (dotNetClass "System.Text.Encoding").UTF8
            proc = (dotNetClass "System.Diagnostics.Process").Start info
            local stdoutTask = proc.StandardOutput.ReadToEndAsync()
            local stderrTask = proc.StandardError.ReadToEndAsync()
            while not proc.HasExited do
            (
                windows.processPostedMessages()
                sleep 0.05
            )
            local code = proc.ExitCode
            local output = stdoutTask.Result + "\r\n" + stderrTask.Result
            (dotNetClass "System.IO.File").WriteAllText logPath output (dotNetClass "System.Text.Encoding").UTF8
            proc.Dispose()
            code
        )
        catch
        (
            local reason = getCurrentException() as string
            if proc != undefined do try(proc.Dispose())catch()
            try((dotNetClass "System.IO.File").WriteAllText logPath reason (dotNetClass "System.Text.Encoding").UTF8)catch()
            throw reason
        )
    ),

    fn externalReportFolder =
    (
        local folder = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\reports\\" + (newRunId())
        (dotNetClass "System.IO.Directory").CreateDirectory folder
        folder
    ),

    fn beginFix =
    (
        fixErrors = #()
        collectingFixErrors = true
        lastError = ""
        local folder = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\backups"
        try
        (
            (dotNetClass "System.IO.Directory").CreateDirectory folder
            lastBackup = folder + "\\" + (currentMaxStem()) + "_" + (newRunId()) + ".max"
            if not (saveMaxFile lastBackup quiet:true useNewFile:false clearNeedSaveFlag:false) do throw "备份保存失败"
            if not doesFileExist lastBackup do throw "未找到备份文件"
            true
        )
        catch
        (
            lastError = "未能建立修改前备份，已停止修改：" + exceptionText "未知错误"
            addRuntimeError "修改前备份" lastError
            collectingFixErrors = false
            false
        )
    ),

    fn endFix =
    (
        collectingFixErrors = false
        try(setSaveRequired true)catch()
        if fixErrors.count > 0 do lastError = "部分修改失败，请查看报错；原场景备份：" + lastBackup
        fixErrors.count == 0
    ),

    fn appendFixErrors =
    (
        join report fixErrors
        fixErrors = #()
    ),

    fn saveCurrentScene =
    (
        local path = currentMaxFullPath()
        if path == "" do
        (
            addRuntimeError "保存 MAX" "尚未保存的场景：去路径结果保留在内存，请先另存 MAX。"
            return false
        )
        try
        (
            if not (saveMaxFile path quiet:true useNewFile:true) do throw "保存返回失败"
            true
        )
        catch(addRuntimeError "保存 MAX" (exceptionText "保存失败"); false)
    ),

    fn runExternalCheck =
    (
        local extTool = undefined
        local cmdLine = ""
        local activeMaxArg = ""
        local activeMaxPath = ""
        local placementError = ""
        local jsonPath = ""
        local csvPath = ""
        local txtPath = ""
        local maxDisplayPath = ""
        local logPath = ""
        local waitCount = 0
        local exitCode = -1

        try(placementError = currentMaxPlacementError())catch(placementError = "")
        if not externalRootManual and placementError != "" do
        (
            lastError = placementError
            return false
        )

        /*
            当前打开的 MAX 是多 MAX 判断的唯一可信依据。
            每次执行都重新同步，避免沿用界面之前保存的旧 externalRoot。
        */
        try
        (
            local currentRoot = currentMaxResourceRoot()
            if not externalRootManual and currentRoot != "" and doesDirectoryExist currentRoot do
                externalRoot = currentRoot
        )
        catch()

        if externalRoot == "" do
        (
            lastError = "请先选择资源根目录。"
            return false
        )
        if not doesDirectoryExist externalRoot do
        (
            lastError = "外部检查目录不存在。"
            return false
        )

        extTool = findExternalTool()
        if extTool == undefined do
        (
            lastError = "未找到 ConquerAssetTool.exe 或 ConquerAssetTool.py。请把外部工具放在本脚本同目录。"
            return false
        )

        externalTool = extTool
        externalOutput = externalReportFolder()
        jsonPath = externalOutput + "\\conquer_asset_check.json"
        csvPath = externalOutput + "\\conquer_asset_check.csv"
        txtPath = externalOutput + "\\conquer_asset_check.txt"
        maxDisplayPath = externalOutput + "\\conquer_asset_check_max.txt"
        logPath = externalOutput + "\\conquer_asset_check_run.log"
        try(deleteFile jsonPath)catch()
        try(deleteFile csvPath)catch()
        try(deleteFile txtPath)catch()
        try(deleteFile maxDisplayPath)catch()
        try(deleteFile logPath)catch()
        try(activeMaxPath = currentMaxFullPath())catch(activeMaxPath = "")
        if not externalRootManual and activeMaxPath != "" and doesFileExist activeMaxPath do
            activeMaxArg = " --active-max " + (quotePath activeMaxPath)
        if matchPattern (toLower extTool) pattern:"*.py" then
            cmdLine = " check " + (quotePath externalRoot) + " --output " + (quotePath externalOutput) + activeMaxArg
        else
            cmdLine = " check " + (quotePath externalRoot) + " --output " + (quotePath externalOutput) + activeMaxArg

        try
        (
            exitCode = runExternalProcess extTool cmdLine logPath
        )
        catch
        (
            lastError = "外部检查执行失败：" + (exceptionText "未知错误")
            return false
        )

        while waitCount < 100 and not (doesFileExist maxDisplayPath or doesFileExist csvPath or doesFileExist jsonPath or doesFileExist txtPath) do
        (
            sleep 0.1
            waitCount += 1
        )
        if (exitCode == 0 or exitCode == 1) and (doesFileExist maxDisplayPath or doesFileExist csvPath or doesFileExist jsonPath or doesFileExist txtPath) then
        (
            lastError = ""
            true
        )
        else
        (
            lastError = "外部检查未生成报告。\n退出码：" + (exitCode as string) + "\n工具：" + extTool + "\n运行日志：" + logPath
            false
        )
    ),

    fn runExternalHierarchyFix moveUnrelated =
    (
        local extTool = undefined
        local cmdLine = ""
        local moveArg = ""
        local activeMaxArg = ""
        local activeMaxPath = ""
        local fixPath = ""
        local logPath = ""
        local waitCount = 0
        local exitCode = -1
        local placementError = ""

        try(placementError = currentMaxPlacementError())catch(placementError = "")
        if placementError != "" do
        (
            lastError = placementError
            return false
        )

        /*
            当前打开的 MAX 是多 MAX 判断的唯一可信依据。
            每次执行都重新同步，避免沿用界面之前保存的旧 externalRoot。
        */
        try
        (
            local currentRoot = currentMaxResourceRoot()
            if currentRoot != "" and doesDirectoryExist currentRoot do
                externalRoot = currentRoot
        )
        catch()

        if externalRoot == "" do
        (
            lastError = "请先选择资源根目录。"
            return false
        )
        if not doesDirectoryExist externalRoot do
        (
            lastError = "外部检查目录不存在。"
            return false
        )

        extTool = findExternalTool()
        if extTool == undefined do
        (
            lastError = "未找到 ConquerAssetTool.exe 或 ConquerAssetTool.py。请把外部工具放在本脚本同目录。"
            return false
        )

        if moveUnrelated then moveArg = " --move-unrelated"
        try(activeMaxPath = currentMaxFullPath())catch(activeMaxPath = "")
        if activeMaxPath != "" and doesFileExist activeMaxPath do
            activeMaxArg = " --active-max " + (quotePath activeMaxPath)
        externalTool = extTool
        externalOutput = externalReportFolder()
        fixPath = externalOutput + "\\conquer_hierarchy_fix.json"
        logPath = externalOutput + "\\conquer_hierarchy_fix_run.log"
        try(deleteFile fixPath)catch()
        try(deleteFile logPath)catch()
        if matchPattern (toLower extTool) pattern:"*.py" then
            cmdLine = " fix-hierarchy " + (quotePath externalRoot) + " --output " + (quotePath externalOutput) + moveArg + activeMaxArg
        else
            cmdLine = " fix-hierarchy " + (quotePath externalRoot) + " --output " + (quotePath externalOutput) + moveArg + activeMaxArg

        try
        (
            exitCode = runExternalProcess extTool cmdLine logPath
        )
        catch
        (
            lastError = "外部层级补全执行失败：" + (exceptionText "未知错误")
            return false
        )

        while waitCount < 100 and not doesFileExist fixPath do
        (
            sleep 0.1
            waitCount += 1
        )
        if doesFileExist fixPath and exitCode == 0 then
        (
            -- Refresh bitmap references after the source files have moved.
            stripProductionTexturePaths()
            lastError = ""
            true
        )
        else
        (
            lastError = "外部层级补全未通过。\n退出码：" + (exitCode as string) + "\n工具：" + extTool + "\n运行日志：" + logPath
            false
        )
    ),

    fn runDDSDetection installerPath =
    (
        local extTool = undefined
        local cmdLine = ""
        local outputFolder = ""
        local reportPath = ""
        local logPath = ""
        local waitCount = 0
        local exitCode = -1

        extTool = findExternalTool()
        if extTool == undefined do
        (
            lastError = "未找到 ConquerAssetTool.exe 或 ConquerAssetTool.py。"
            return false
        )

        externalTool = extTool
        outputFolder = externalReportFolder()
        externalOutput = outputFolder
        reportPath = outputFolder + "\\conquer_dds_tool.txt"
        logPath = outputFolder + "\\conquer_dds_tool_run.log"
        try(deleteFile reportPath)catch()
        try(deleteFile logPath)catch()

        if matchPattern (toLower extTool) pattern:"*.py" then
            cmdLine = " detect-dds --output " + (quotePath outputFolder)
        else
            cmdLine = " detect-dds --output " + (quotePath outputFolder)
        if installerPath != undefined and installerPath != "" do
            cmdLine += " --installer " + (quotePath installerPath)
        if externalRoot != "" and doesDirectoryExist externalRoot do
            cmdLine += " --search-root " + (quotePath externalRoot)

        try
        (
            exitCode = runExternalProcess extTool cmdLine logPath
        )
        catch
        (
            lastError = "DDS工具检测执行失败：" + (exceptionText "未知错误")
            return false
        )

        while waitCount < 100 and not doesFileExist reportPath do
        (
            sleep 0.1
            waitCount += 1
        )
        if doesFileExist reportPath then
        (
            try(ShellLaunch reportPath "")catch()
            lastError = ""
            true
        )
        else
        (
            lastError = "DDS工具检测未生成报告。\n退出码：" + (exitCode as string) + "\n日志：" + logPath
            false
        )
    ),

    fn runDDSConversion sourcePaths = (runTextureConversion sourcePaths "dds"),

    fn runPNGConversion sourcePaths = (runTextureConversion sourcePaths "png"),

    fn runTextureConversion sourcePaths kind =
    (
        lastConversionText = ""
        if lastError != "" then return false
        local root = outputResourceRoot()
        if root == "" do (lastError = "请先把 MAX 保存到资源文件夹。"; return false)
        if sourcePaths == undefined or sourcePaths.count == 0 do (lastError = "没有可转换的生产 TGA。"; return false)
        local exeFile = findExternalTool()
        if exeFile == undefined do (lastError = "缺少整合包 ConquerAssetTool.exe，请重新解压完整插件。"; return false)
        externalOutput = externalReportFolder()
        local prefix = "conquer_" + kind + "_convert"
        local statusFile = externalOutput + "\\" + prefix + ".status"
        local reportFile = externalOutput + "\\" + prefix + ".txt"
        local proc = undefined
        try
        (
            local args = "convert-" + kind
            for source in sourcePaths do args += " " + quotePath source
            args += " --output " + quotePath (root + "\\C3") + " --report-output " + quotePath externalOutput
            if kind == "dds" do
            (
                args += " --size 0 --mips 2"
                if psRefine do args += " --ps-refine --ps-version " + psVersion
            )
            local info = dotNetObject "System.Diagnostics.ProcessStartInfo"
            info.FileName = exeFile
            info.Arguments = args
            info.WorkingDirectory = scriptFolder()
            info.UseShellExecute = false
            info.CreateNoWindow = true
            proc = (dotNetClass "System.Diagnostics.Process").Start info
            while not proc.HasExited do
            (
                windows.processPostedMessages()
                sleep 0.05
            )
            local code = proc.ExitCode
            proc.Dispose()
            local lines = readUtf8Lines statusFile
            if doesFileExist reportFile do lastConversionText = (dotNetClass "System.IO.File").ReadAllText reportFile
            if code != 0 or lines.count == 0 do throw ("转换失败（退出码 " + code as string + "）。\n" + lastConversionText)
            if stripUtf8Bom lines[1] != "OK" do throw lastConversionText
            lastError = ""
            true
        )
        catch
        (
            lastError = exceptionText "转换工具未正常完成，请检查整合包版本。"
            if proc != undefined do try(proc.Dispose())catch()
            false
        )
    ),

    fn externalCsvPath =
    (
        if externalOutput == "" then "" else externalOutput + "\\conquer_asset_check.csv"
    ),

    fn externalJsonPath =
    (
        if externalOutput == "" then "" else externalOutput + "\\conquer_asset_check.json"
    ),

    fn externalTextPath =
    (
        if externalOutput == "" then "" else externalOutput + "\\conquer_asset_check.txt"
    ),

    fn externalMaxDisplayPath =
    (
        if externalOutput == "" then "" else externalOutput + "\\conquer_asset_check_max.txt"
    ),

    fn readUtf8Lines filePath =
    (
        local result = #()
        local encodingClass = undefined
        local utf8Reader = undefined
        local gbkReader = undefined
        local sample = ""
        local line = ""
        local f = undefined

        if filePath == "" or not doesFileExist filePath then return result

        try
        (
            encodingClass = dotNetClass "System.Text.Encoding"
            try(utf8Reader = dotNetObject "System.IO.StreamReader" filePath encodingClass.UTF8)catch(utf8Reader = undefined)
            if utf8Reader != undefined do
            (
                while not utf8Reader.EndOfStream do
                (
                    line = ""
                    try(line = utf8Reader.ReadLine() as string)catch(line = "")
                    append result line
                )
                try(utf8Reader.Close())catch()
                for line in result do sample += line
                if sample != "" and (findString sample "�" != undefined or findString sample "锘" != undefined) then
                (
                    result = #()
                    try(gbkReader = dotNetObject "System.IO.StreamReader" filePath (encodingClass.GetEncoding 936))catch(gbkReader = undefined)
                    if gbkReader != undefined do
                    (
                        while not gbkReader.EndOfStream do
                        (
                            line = ""
                            try(line = gbkReader.ReadLine() as string)catch(line = "")
                            append result line
                        )
                        try(gbkReader.Close())catch()
                    )
                )
            )
            if result.count > 0 then return result
        )
        catch()

        try(f = openFile filePath mode:"rt")catch(f = undefined)
        if f != undefined do
        (
            while not eof f do
            (
                local line = ""
                try(line = readLine f)catch(line = "")
                append result line
            )
            close f
        )
        result
    ),

    fn stripUtf8Bom value =
    (
        local text = asText value
        if text.count > 0 and (substring text 1 1) == "﻿" do
            text = substring text 2 (text.count - 1)
        text
    ),

    fn readExternalText =
    (
        local result = ""
        local txtPath = externalTextPath()
        local lines = #()
        if txtPath == "" or not doesFileExist txtPath then return result

        lines = readUtf8Lines txtPath
        for line in lines do
        (
            line = stripUtf8Bom line
            result += line + "\r\n"
        )
        result
    ),

    fn openExternalText =
    (
        local target = externalTextPath()
        if target == "" or not doesFileExist target then
        (
            messageBox "请先成功执行一次外部检查。" title:"征服MAX模型检查器"
            return false
        )
        try
        (
            ShellLaunch target ""
            true
        )
        catch
        (
            messageBox ("TXT 报告打开失败：\n" + (exceptionText "未知错误")) title:"征服MAX模型检查器"
            false
        )
    ),

    fn hasDirectMaxFiles folder =
    (
        local files = #()
        if folder == "" or not doesDirectoryExist folder then return false
        try(files = getFiles (folder + "\\*.max"))catch(files = #())
        files.count > 0
    ),

    fn hasResourceSiblingFolders folder =
    (
        local found = false
        if folder == "" or not doesDirectoryExist folder then return false
        if doesDirectoryExist (folder + "\\C3") do found = true
        if doesDirectoryExist (folder + "\\MAX") do found = true
        if doesDirectoryExist (folder + "\\设计稿") do found = true
        if doesDirectoryExist (folder + "\\渲染图") do found = true
        found
    ),

    fn parentFolderOf folder =
    (
        local normalized = trimTrailingPathSeparators folder
        local parent = ""
        if normalized == "" then return ""
        try(parent = getFilenamePath normalized)catch(parent = "")
        parent = trimTrailingPathSeparators parent
        parent
    ),

    fn isDesktopOrDriveRootFolder folder =
    (
        local normalized = trimTrailingPathSeparators (substituteString (asText folder) "/" "\\")
        local desktop = ""
        if normalized == "" then return false
        try(desktop = trimTrailingPathSeparators (substituteString (desktopFolder()) "/" "\\"))catch(desktop = "")
        if desktop != "" and (toLower normalized) == (toLower desktop) do return true
        if normalized.count <= 3 and findString normalized ":" != undefined do return true
        false
    ),

    fn findResourceMaxFolder root =
    (
        local dirs = #()
        if root == "" or not doesDirectoryExist root then return ""
        if hasDirectMaxFiles root then return root
        try(dirs = getDirectories (root + "\\*"))catch(dirs = #())
        for d in dirs where hasDirectMaxFiles d do return d
        ""
    ),

    fn validateExternalRoot =
    (
        local root = externalRoot
        local maxFolder = ""
        local maxFiles = #()
        local ddsFiles = #()

        if root == "" then return "目录判断：未选择资源目录。"
        if not doesDirectoryExist root then return "目录判断：不通过，目录不存在。"

        maxFolder = findResourceMaxFolder root
        if maxFolder != "" do
        (
            if toLower maxFolder == toLower root then
                return "目录判断：通过，当前目录包含 MAX 文件，可直接检查。"
            else
                return ("目录判断：通过，已找到 MAX 文件目录“" + getFilenameFile maxFolder + "”；标准名称建议为 MAX。")
        )

        try(maxFiles = getFiles (root + "\\*.max"))catch(maxFiles = #())
        try(ddsFiles = getFiles (root + "\\*.dds"))catch(ddsFiles = #())
        if maxFiles.count > 0 or ddsFiles.count > 0 then
            return "目录判断：不通过，当前目录已有 MAX/DDS 文件，但没有可识别的 MAX 文件目录。"

        "目录判断：不通过，未找到包含 MAX 文件的目录；建议选择资源包目录，或直接选择 MAX 文件夹。"
    ),

    fn resourceRootFromMaxFile filePath =
    (
        if filePath == undefined or filePath == "" then return ""
        local folder = trimTrailingPathSeparators (getFilenamePath filePath)
        local parent = parentFolderOf folder
        if isDesktopOrDriveRootFolder folder then return ""
        if (toLower (filenameFromPath folder)) == "max" then
        (
            if isDesktopOrDriveRootFolder parent then return ""
            parent
        )
        else if (toLower (filenameFromPath folder)) == "3d" and hasResourceSiblingFolders parent and not isDesktopOrDriveRootFolder parent then parent
        else folder
    ),

    fn currentMaxResourceRoot =
    (
        local currentFile = ""
        try(currentFile = currentMaxFullPath())catch(currentFile = "")
        resourceRootFromMaxFile currentFile
    ),

    fn currentMaxPlacementError =
    (
        local path = currentMaxFullPath()
        if path == "" then "请先将 MAX 保存到独立的资源文件夹，再整理或出图。"
        else if resourceRootFromMaxFile path == "" then "MAX 必须位于独立资源文件夹内；不能直接以桌面、盘符根目录作为资源包。"
        else ""
    ),

    fn syncExternalRootToCurrentMax =
    (
        local currentRoot = ""
        try(currentRoot = currentMaxResourceRoot())catch(currentRoot = "")
        if currentRoot != "" and doesDirectoryExist currentRoot then
        (
            externalRoot = currentRoot
            true
        )
        else
            false
    ),

    fn openMaxParentFolder =
    (
        local root = currentMaxResourceRoot()
        if root == "" do root = externalRoot
        if root == "" or not doesDirectoryExist root do
        (
            lastError = "无法找到当前 MAX 文件夹。请先保存 MAX 文件，或点击“从MAX拾取”。"
            return false
        )
        externalRoot = root
        try
        (
            ShellLaunch root ""
            lastError = ""
            true
        )
        catch
        (
            lastError = "资源文件夹打开失败：" + (exceptionText "未知错误")
            false
        )
    ),

    fn saveSceneToMaxFolder =
    (
        local root = currentMaxResourceRoot()
        if root == "" do (lastError = currentMaxPlacementError(); return false)
        local folder = root + "\\MAX"
        local source = currentMaxFullPath()
        local leaf = filenameFromPath source
        local target = folder + "\\" + leaf
        try
        (
            makeDir folder
            if doesFileExist target and toLower target != toLower source do
            (
                local archive = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\backups\\整理前旧MAX\\" + (newRunId())
                (dotNetClass "System.IO.Directory").CreateDirectory archive
                (dotNetClass "System.IO.File").Copy target (archive + "\\" + leaf) false
            )
            if not (saveMaxFile target quiet:true useNewFile:true clearNeedSaveFlag:true) do throw "保存返回失败"
            if not doesFileExist target do throw "保存后文件不存在"
            if toLower (currentMaxFullPath()) != toLower target do throw "当前场景未切换到整理后的保存路径"
            externalRoot = root
            lastError = ""
            true
        )
        catch(lastError = "MAX 保存失败：" + exceptionText "未知错误"; false)
    ),

    fn readExternalCsv wantedStatus =
    (
        local result = ""
        local csvPath = externalCsvPath()
        local lines = #()
        local firstLine = true
        if csvPath == "" or not doesFileExist csvPath then return result

        lines = readUtf8Lines csvPath
        for line in lines do
        (
            line = stripUtf8Bom line
            if firstLine then
            (
                firstLine = false
            )
            else
            (
                if line != "" do
                (
                    local matchedLine = false
                    if matchPattern line pattern:(wantedStatus + ",*") ignoreCase:false do matchedLine = true
                    if matchPattern line pattern:("\"" + wantedStatus + "\",*") ignoreCase:false do matchedLine = true
                    if matchedLine do
                        result += "外部 | " + line + "\r\n"
                )
            )
        )
        result
    ),

    fn parseCsvLine line =
    (
        local fields = #()
        local current = ""
        local quoted = false
        local i = 1
        while i <= line.count do
        (
            local ch = substring line i 1
            if ch == "\"" then
            (
                if quoted and i < line.count and (substring line (i + 1) 1) == "\"" then
                (
                    current += "\""
                    i += 1
                )
                else
                    quoted = not quoted
            )
            else if ch == "," and not quoted then
            (
                append fields current
                current = ""
            )
            else
                current += ch
            i += 1
        )
        append fields current
        fields
    ),

    fn compactExternalCsv wantedStatus =
    (
        local groups = #()
        local csvPath = externalCsvPath()
        local result = ""
        local lines = #()
        if csvPath == "" or not doesFileExist csvPath then return result

        lines = readUtf8Lines csvPath
        for line in lines do
        (
            line = stripUtf8Bom line
            if line != "" do
            (
                local fields = parseCsvLine line
                if fields.count >= 5 and fields[1] != "结果" and fields[1] == wantedStatus do
                (
                    local groupIndex = 0
                    for i = 1 to groups.count do
                    (
                        if groups[i][1] == fields[2] and groupIndex == 0 do
                            groupIndex = i
                    )
                    if groupIndex == 0 then
                        append groups #(fields[2], 1, #(fields[3]), fields[4], fields[5])
                    else
                    (
                        groups[groupIndex][2] = groups[groupIndex][2] + 1
                        local targets = groups[groupIndex][3]
                        if findItem targets fields[3] == 0 and targets.count < 4 do
                            append targets fields[3]
                        groups[groupIndex][3] = targets
                        if groups[groupIndex][4] == "" do
                            groups[groupIndex][4] = fields[4]
                        if groups[groupIndex][5] == "" do
                            groups[groupIndex][5] = fields[5]
                    )
                )
            )
        )

        for g in groups do
        (
            local targetText = compactTargetText g[3] g[2]
            local actionText = asText g[5]
            if actionText == "" do actionText = "请根据检查项修正后重新检查。"
            if wantedStatus == "报错" do
                actionText = (compactShortText g[4] 120) + "；" + actionText
            result += "外部 | " + wantedStatus + " | " + g[1] + " | " + targetText + " | " + actionText + "\r\n"
        )
        result
    ),

    fn compactExternalText wantedStatus =
    (
        local groups = #()
        local txtPath = externalTextPath()
        local result = ""
        local lines = #()
        if txtPath == "" or not doesFileExist txtPath then return result

        lines = readUtf8Lines txtPath
        for line in lines do
        (
            line = stripUtf8Bom line
            local fields = #()
            if line != "" do
            (
                fields = filterString line " | "
                if fields.count >= 5 and fields[1] == wantedStatus do
                (
                    local groupIndex = 0
                    for i = 1 to groups.count do
                    (
                        if groups[i][1] == fields[2] and groupIndex == 0 do
                            groupIndex = i
                    )
                    if groupIndex == 0 then
                        append groups #(fields[2], 1, #(fields[3]), fields[4], fields[5])
                    else
                    (
                        groups[groupIndex][2] = groups[groupIndex][2] + 1
                        local targets = groups[groupIndex][3]
                        if findItem targets fields[3] == 0 and targets.count < 4 do
                            append targets fields[3]
                        groups[groupIndex][3] = targets
                        if groups[groupIndex][4] == "" do
                            groups[groupIndex][4] = fields[4]
                        if groups[groupIndex][5] == "" do
                            groups[groupIndex][5] = fields[5]
                    )
                )
            )
        )
        for g in groups do
        (
            local targetText = compactTargetText g[3] g[2]
            local actionText = asText g[5]
            if actionText == "" do actionText = "请根据检查项修正后重新检查。"
            if wantedStatus == "报错" do
                actionText = (compactShortText g[4] 120) + "；" + actionText
            result += "外部 | " + wantedStatus + " | " + g[1] + " | " + targetText + " | " + actionText + "\r\n"
        )
        result
    ),

    fn compactExternalDisplay wantedStatus =
    (
        local displayPath = externalMaxDisplayPath()
        local result = ""
        local wantedToken = "PASS"
        if wantedStatus == "不通过" then wantedToken = "FAIL"
        if wantedStatus == "待确认" then wantedToken = "WAIT"
        if wantedStatus == "报错" then wantedToken = "ERROR"
        if displayPath == "" or not doesFileExist displayPath then return result

        local lines = readUtf8Lines displayPath
        for line in lines do
        (
            line = stripUtf8Bom line
            if line != "" and matchPattern line pattern:(wantedToken + "|*") do
            (
                local prefixLength = wantedToken.count + 1
                if line.count >= prefixLength do
                    result += "外部 | " + wantedStatus + " | " + (substring line (prefixLength + 1) (line.count - prefixLength)) + "\r\n"
            )
        )
        result
    ),

    fn externalReportHasBlockingIssues =
    (
        local displayPath = externalMaxDisplayPath()
        local csvPath = externalCsvPath()
        local lines = #()
        local fields = #()
        if displayPath != "" and doesFileExist displayPath do
        (
            lines = readUtf8Lines displayPath
            for line in lines do
            (
                line = stripUtf8Bom line
                if matchPattern line pattern:"FAIL|*" or matchPattern line pattern:"WAIT|*" or matchPattern line pattern:"ERROR|*" do return true
            )
        )
        if csvPath != "" and doesFileExist csvPath do
        (
            lines = readUtf8Lines csvPath
            for line in lines do
            (
                fields = parseCsvLine (stripUtf8Bom line)
                if fields.count >= 1 do
                (
                    if fields[1] == "不通过" or fields[1] == "待确认" or fields[1] == "报错" do return true
                )
            )
        )
        false
    ),

    fn openExternalReport jsonReport =
    (
        local target = if jsonReport then externalJsonPath() else externalCsvPath()
        if target == "" or not doesFileExist target then
        (
            messageBox "请先成功执行一次外部检查。" title:"征服MAX模型检查器"
            return false
        )
        try
        (
            ShellLaunch target ""
            true
        )
        catch
        (
            messageBox ("报告打开失败：\n" + (exceptionText "未知错误")) title:"征服MAX模型检查器"
            false
        )
    ),

    fn makeDesktopPlan =
    (
        local desktop = desktopFolder()
        local extTool = undefined
        local destination = ""
        local cmdLine = ""
        local planPath = ""
        local logPath = ""
        local waitCount = 0
        local exitCode = -1

        if desktop == "" then
        (
            lastError = "未找到 Windows 桌面目录。"
            return false
        )

        extTool = findExternalTool()
        if extTool == undefined then
        (
            lastError = "未找到外部工具。请把 ConquerAssetTool.exe 或 ConquerAssetTool.py 放在本脚本同目录。"
            return false
        )
        externalTool = extTool
        destination = scriptFolder() + "桌面整理预览"
        makeDir destination
        planPath = destination + "\\conquer_organize_plan.json"
        logPath = destination + "\\conquer_organize_run.log"
        try(deleteFile planPath)catch()
        try(deleteFile logPath)catch()
        if matchPattern (toLower extTool) pattern:"*.py" then
            cmdLine = " organize " + (quotePath desktop) + " " + (quotePath destination)
        else
            cmdLine = " organize " + (quotePath desktop) + " " + (quotePath destination)
        try
        (
            exitCode = runExternalProcess extTool cmdLine logPath
        )
        catch
        (
            lastError = "桌面整理预览执行失败：" + (exceptionText "未知错误")
            return false
        )

        while waitCount < 100 and not doesFileExist planPath do
        (
            sleep 0.1
            waitCount += 1
        )
        if doesFileExist planPath then
            true
        else
        (
            lastError = "桌面整理预览未生成计划。\n退出码：" + (exitCode as string) + "\n桌面目录：" + desktop + "\n运行日志：" + logPath
            false
        )
    ),

    fn add status category target detail suggestion =
    (
        append report (ConquerCheckItem status:status category:category target:(asText target) detail:(asText detail) suggestion:(asText suggestion))
    ),

    fn resetReport =
    (
        report = #()
    ),

    fn csvEscape v =
    (
        local s = asText v
        s = substituteString s "\"" "\"\""
        "\"" + s + "\""
    ),

    fn getGeometryNodes =
    (
        for n in geometry where isProductionNode n and
            not (matchPattern (classOf n as string) pattern:"*Bone*" ignoreCase:true) and
            not (matchPattern (classOf n as string) pattern:"*Biped*" ignoreCase:true) and
            ((not selectedOnly) or (isSelected n)) collect n
    ),

    fn getMaterialNodes =
    (
        for n in getGeometryNodes() where n.material != undefined collect n
    ),

    fn collectBitmapTexturesRecursive value visited =
    (
        local out = #()
        if value == undefined then return out

        if classOf value == Bitmaptexture do
        (
            append out value
            return out
        )

        local handle = 0
        try(handle = getHandleByAnim value)catch(handle = 0)
        if handle != 0 do
        (
            if findItem visited handle > 0 then return out
            append visited handle
        )

        if classOf value == Array do
        (
            for item in value do
            (
                local childMaps = #()
                try(childMaps = collectBitmapTexturesRecursive item visited)catch(childMaps = #())
                join out childMaps
            )
            return out
        )

        local texCount = 0
        try(texCount = getNumSubTexmaps value)catch(texCount = 0)
        for i = 1 to texCount do
        (
            local subTex = undefined
            local childMaps = #()
            try(subTex = getSubTexmap value i)catch(subTex = undefined)
            if subTex != undefined do
            (
                try(childMaps = collectBitmapTexturesRecursive subTex visited)catch(childMaps = #())
                join out childMaps
            )
        )

        local subCount = 0
        try(subCount = getNumSubMtls value)catch(subCount = 0)
        for i = 1 to subCount do
        (
            local subMtl = undefined
            local childMaps = #()
            try(subMtl = getSubMtl value i)catch(subMtl = undefined)
            if subMtl != undefined do
            (
                try(childMaps = collectBitmapTexturesRecursive subMtl visited)catch(childMaps = #())
                join out childMaps
            )
        )

        local knownProps = #(#diffuseMap, #opacityMap, #bumpMap, #specularMap, #selfIllumMap, #reflectionMap, #refractionMap, #displacementMap, #filterMap, #bakedMaterial, #originalMaterial)
        for p in knownProps do
        (
            local child = undefined
            local childMaps = #()
            try(child = getProperty value p)catch(child = undefined)
            if child != undefined do
            (
                try(childMaps = collectBitmapTexturesRecursive child visited)catch(childMaps = #())
                join out childMaps
            )
        )
        makeUniqueArray out
    ),

    fn materialNameKey m =
    (
        local n = ""
        try(n = toLower (asText m.name))catch(n = "")
        n
    ),

    fn bitmapFilenameStemKey b =
    (
        local fnm = ""
        local leaf = ""
        try(fnm = asText b.filename)catch(fnm = "")
        leaf = filenameFromPath fnm
        toLower (getFilenameFile leaf)
    ),

    fn stripLooseNamePrefix value =
    (
        local s = toLower (asText value)
        local ch = ""
        while s.count > 0 do
        (
            ch = substring s 1 1
            if (findString "0123456789 _-.#()" ch) != undefined then
                s = substring s 2 (s.count - 1)
            else
                exit
        )
        s
    ),

    fn looseTextureNameMatch materialKey textureKey =
    (
        local mk = stripLooseNamePrefix materialKey
        local tk = stripLooseNamePrefix textureKey
        if mk == "" or tk == "" then return false
        if mk == tk then return true
        if tk.count >= 4 and (findString mk tk) != undefined then return true
        if mk.count >= 4 and (findString tk mk) != undefined then return true
        false
    ),

    fn bitmapTexturesFromMatchingSceneMaterials prodMats =
    (
        local out = #()
        local wantedNames = #()
        local sceneMats = #()
        local key = ""

        if prodMats == undefined then return out
        for m in prodMats where m != undefined do
        (
            key = materialNameKey m
            if key != "" and findItem wantedNames key == 0 do append wantedNames key
        )

        if wantedNames.count == 0 then return out
        try(sceneMats = scenematerials as array)catch(sceneMats = #())
        for m in sceneMats where m != undefined do
        (
            key = materialNameKey m
            local matched = false
            if key != "" do
            (
                for wanted in wantedNames where not matched do
                    if looseTextureNameMatch wanted key do matched = true
            )
            if matched do
                try(join out (bitmapTexturesFromMaterialList #(m)))catch()
        )
        makeUniqueArray out
    ),

    fn bitmapTexturesFromKnownFilesMatchingMaterialNames prodMats =
    (
        local out = #()
        local wantedNames = #()
        local knownMaps = #()
        local mats = #()
        local slotCount = 24
        local activeMaterial = undefined
        local key = ""

        if prodMats == undefined then return out
        for m in prodMats where m != undefined do
        (
            key = materialNameKey m
            if key != "" and findItem wantedNames key == 0 do append wantedNames key
        )
        if wantedNames.count == 0 then return out

        try(join mats (scenematerials as array))catch()
        try(slotCount = meditMaterials.count)catch()
        if slotCount < 24 do slotCount = 24
        for i = 1 to slotCount do
        (
            local m = undefined
            try(m = meditMaterials[i])catch(m = undefined)
            if m != undefined do append mats m
        )
        try(activeMaterial = medit.GetCurMtl())catch(activeMaterial = undefined)
        if activeMaterial != undefined do append mats activeMaterial

        try(join knownMaps (bitmapTexturesFromMaterialList mats))catch()
        try(join knownMaps (getClassInstances Bitmaptexture target:meditMaterials))catch()
        if activeMaterial != undefined do
            try(join knownMaps (getClassInstances Bitmaptexture target:activeMaterial))catch()
        try(join knownMaps (getClassInstances Bitmaptexture))catch()
        knownMaps = makeUniqueArray knownMaps

        for b in knownMaps where b != undefined do
        (
            key = bitmapFilenameStemKey b
            if key != "" do
            (
                local matched = false
                for wanted in wantedNames where not matched do
                    if looseTextureNameMatch wanted key do matched = true
                if matched do append out b
            )
        )
        makeUniqueArray out
    ),

    fn getBodyNodes =
    (
        for n in geometry where isValidNode n and (toLower n.name) == "v_body" collect n
    ),

    fn isGroupedNode n =
    (
        local grouped = false
        if not isValidNode n then return false
        try(if isGroupHead n then grouped = true)catch()
        try(if isGroupMember n then grouped = true)catch()
        grouped
    ),

    fn groupedNodes =
    (
        for n in objects where isProductionNode n and isGroupedNode n collect n
    ),

    fn getNodeDims nodes =
    (
        if nodes == undefined or nodes.count == 0 then return undefined

        local hasAny = false
        local mn = [0,0,0]
        local mx = [0,0,0]

        for n in nodes where isValidNode n do
        (
            /* Combine all node dimensions in world coordinates. */
            local bb = nodeGetBoundingBox n (matrix3 1)
            if not hasAny then
            (
                mn = bb[1]
                mx = bb[2]
                hasAny = true
            )
            else
            (
                mn.x = amin mn.x bb[1].x
                mn.y = amin mn.y bb[1].y
                mn.z = amin mn.z bb[1].z
                mx.x = amax mx.x bb[2].x
                mx.y = amax mx.y bb[2].y
                mx.z = amax mx.z bb[2].z
            )
        )

        if hasAny then (mx - mn) else undefined
    ),

    fn importBaseBody filePath =
    (
        lastError = ""
        if filePath == undefined or filePath == "" do
        (
            lastError = "没有选择基础体文件。"
            return false
        )
        if not doesFileExist filePath do
        (
            lastError = "基础体文件不存在。"
            return false
        )

        if importedBaseNodes.count > 0 do
        (
            try(delete importedBaseNodes)catch()
        )
        importedBaseNodes = #()
        importedBaseMaterials = #()
        local oldNodes = #()
        local oldMaterials = #()
        try(oldNodes = objects as array)catch()
        try(oldMaterials = scenematerials as array)catch()
        try(clearSelection())catch()
        local ok = false
        local newNodes = #()

        try
        (
            /* 先让 Max 自动避开重名弹窗，再由脚本统一把导入对象改成 baseObs_#。 */
            mergeMAXFile filePath #select #autoRenameDups
            try(newNodes = selection as array)catch(newNodes = #())
            ok = true
        )
        catch
        (
            ok = false
            lastError = exceptionText "MAX 文件合并命令执行失败。"
        )

        if not ok then
        (
            local possibleNewNodes = for n in objects where (findItem oldNodes n) == 0 collect n
            if possibleNewNodes.count > 0 do try(delete possibleNewNodes)catch()
            try(clearSelection())catch()
            if lastError == "" do lastError = "MAX 文件合并命令执行失败。"
            return false
        )

        if newNodes.count == 0 do
        (
            newNodes = for n in objects where (findItem oldNodes n) == 0 collect n
        )
        try(clearSelection())catch()
        if newNodes.count == 0 do
        (
            lastError = "文件已打开但没有检测到新导入对象。"
            return false
        )

        importedBaseNodes = newNodes
        baseFile = filePath
        importedBaseMaterials = #()
        local sceneMaterialsAfter = #()
        try(sceneMaterialsAfter = scenematerials as array)catch()
        for m in sceneMaterialsAfter where (findItem oldMaterials m) == 0 do append importedBaseMaterials m
        for n in importedBaseNodes where isValidNode n and n.material != undefined do append importedBaseMaterials n.material
        importedBaseMaterials = makeUniqueArray importedBaseMaterials

        local matIdx = 1
        for m in importedBaseMaterials where m != undefined do
        (
            try(m.name = "baseObsMat_" + (matIdx as string))catch()
            matIdx += 1
        )

        local idx = 1
        for n in importedBaseNodes where isValidNode n do
        (
            try
            (
                n.name = "baseObs_" + (idx as string)
                idx += 1
            )
            catch(idx += 1)
            try(n.wirecolor = green)catch()
            try(n.showFrozenInGray = false)catch()
        )
        lastError = ""
        importedBaseNodes.count > 0
    ),

    fn faceArea m f =
    (
        local ids = getFace m f
        local a = getVert m ids.x
        local b = getVert m ids.y
        local c = getVert m ids.z
        (length (cross (b - a) (c - a))) * 0.5
    ),

    fn meshReport n =
    (
        local deadVerts = 0
        local zeroFaces = 0
        local badSmooth = 0
        local openEdges = undefined
        local tri = undefined
        local errorText = ""
        local errorStage = "snapshot"

        try
        (
            tri = snapshotAsMesh n
            errorStage = "faces"
            local used = #{}

            for f = 1 to tri.numfaces do
            (
                errorStage = "face:" + (f as string) + " verts"
                local ids = getFace tri f
                used[ids.x] = true
                used[ids.y] = true
                used[ids.z] = true

                errorStage = "face:" + (f as string) + " area"
                if (faceArea tri f) < 0.00001 do zeroFaces += 1

                errorStage = "face:" + (f as string) + " smooth"
                if (getFaceSmoothGroup tri f) != 1 do badSmooth += 1

            )

            errorStage = "deadVerts"
            for v = 1 to tri.numverts where used[v] != true do deadVerts += 1
        )
        catch
        (
            errorText = "阶段=" + errorStage + "；" + (exceptionText "未知错误")
        )

        if tri != undefined do free tri
        #(deadVerts, zeroFaces, badSmooth, openEdges, errorText)
    ),

    fn countNgons n =
    (
        local c = 0
        local ok = true
        try
        (
            if classOf n.baseObject == Editable_Poly do
            (
                local fc = polyOp.getNumFaces n
                for f = 1 to fc do
                (
                    local vs = polyOp.getFaceVerts n f
                    if vs.count > 4 do c += 1
                )
            )
        )
        catch(ok = false)
        if ok then c else undefined
    ),

    fn transformIsClean n =
    (
        local ok = true
        try
        (
            if distance n.pos [0,0,0] > 0.001 do ok = false
            if abs(n.rotation.x) > 0.001 do ok = false
            if abs(n.rotation.y) > 0.001 do ok = false
            if abs(n.rotation.z) > 0.001 do ok = false
            if abs(abs(n.rotation.w) - 1.0) > 0.001 do ok = false
            if abs(n.scale.x - 1.0) > 0.0001 do ok = false
            if abs(n.scale.y - 1.0) > 0.0001 do ok = false
            if abs(n.scale.z - 1.0) > 0.0001 do ok = false
        )
        catch(ok = false)
        ok
    ),

    fn likelyBoneNodes =
    (
        local out = #()
        for n in objects where isProductionNode n do
        (
            local lname = toLower n.name
            local cls = classOf n as string
            if matchPattern cls pattern:"*Bone*" ignoreCase:true or matchPattern cls pattern:"*Biped*" ignoreCase:true do append out n
        )
        out
    ),

    fn animatedNodes =
    (
        local out = #()
        for n in objects where isProductionNode n do
        (
            local kc = 0
            try(kc += numKeys n.position.controller)catch()
            try(kc += numKeys n.rotation.controller)catch()
            try(kc += numKeys n.scale.controller)catch()
            if kc > 0 do append out n
        )
        out
    ),

    fn bitmapTextures =
    (
        /*
            从完整生产材质树收集 BitmapTexture，覆盖 Multi/Sub-Object
            等嵌套材质；这样材质编辑器拾取和路径修复使用同一份集合。
        */
        local out = #()
        local mats = #()
        try(mats = productionMaterialTree())catch(mats = #())
        try(join out (bitmapTexturesFromMaterialList mats))catch()
        for m in mats where m != undefined do
            try(join out (getClassInstances Bitmaptexture target:m))catch()
        if out.count == 0 do
        (
            /*
                部分 Max 文件中，节点材质与场景材质库显示为同名材质，
                但内部贴图依赖没有挂到 productionMaterialTree 的引用链。
                这时按生产材质名反查场景材质库，避免正确赋材质却误报贴图槽。
            */
            local prodMats = #()
            try(prodMats = productionMaterials())catch(prodMats = #())
            try(join out (bitmapTexturesFromMatchingSceneMaterials prodMats))catch()
            if out.count == 0 do
                try(join out (bitmapTexturesFromKnownFilesMatchingMaterialNames prodMats))catch()
        )
        makeUniqueArray out
    ),

    fn bitmapTexturesFromMaterialList mats =
    (
        local out = #()
        local visited = #()
        if mats == undefined then return out
        for m in mats where m != undefined do
        (
            /*
                Compact Material Editor 可以直接把 BitmapTexture 放进槽位，
                直接按属性树递归更稳，不依赖 getClassInstances 的目标扫描。
            */
            try(join out (collectBitmapTexturesRecursive m visited))catch()
        )
        makeUniqueArray out
    ),

    fn allKnownBitmapTextures =
    (
        local mats = #()
        local out = #()
        local slotCount = 24
        local activeMaterial = undefined
        try(join mats (scenematerials as array))catch()
        try(slotCount = meditMaterials.count)catch()
        if slotCount < 24 do slotCount = 24
        for i = 1 to slotCount do
        (
            local m = undefined
            try(m = meditMaterials[i])catch(m = undefined)
            if m != undefined do append mats m
        )
        /*
            Compact Material Editor 当前活动槽位有时不会完整出现在
            meditMaterials 的遍历结果中，额外直接读取当前槽位。
        */
        try(activeMaterial = medit.GetCurMtl())catch(activeMaterial = undefined)
        if activeMaterial != undefined do append mats activeMaterial
        try(join out (bitmapTexturesFromMaterialList mats))catch()
        try(join out (getClassInstances Bitmaptexture target:meditMaterials))catch()
        if activeMaterial != undefined do
            try(join out (getClassInstances Bitmaptexture target:activeMaterial))catch()
        makeUniqueArray out
    ),

    fn knownBitmapTexturesMatchingProductionNames prodMats =
    (
        local out = #()
        local wantedNames = #()
        local allMaps = #()
        local key = ""

        if prodMats == undefined then return out
        for m in prodMats where m != undefined do
        (
            key = materialNameKey m
            if key != "" and findItem wantedNames key == 0 do append wantedNames key
        )

        if wantedNames.count == 0 then return out
        try(join allMaps (allKnownBitmapTextures()))catch(allMaps = #())
        for b in allMaps where b != undefined do
        (
            key = bitmapFilenameStemKey b
            if key != "" do
            (
                local matched = false
                for wanted in wantedNames where not matched do
                    if looseTextureNameMatch wanted key do matched = true
                if matched do append out b
            )
        )
        makeUniqueArray out
    ),

    fn ddsConversionBitmapTextures = (bitmapTextures()),

    fn productionMaterials =
    (
        local out = #()
        for n in getMaterialNodes() do
        (
            local m = undefined
            try(m = n.material)catch(m = undefined)
            if m != undefined do append out m
        )
        makeUniqueArray out
    ),

    fn baseMaterials =
    (
        importedBaseMaterials
    ),

    fn isBaseMaterial m =
    (
        if m == undefined then false else
        (
            local mn = toLower (asText m.name)
            (findItem importedBaseMaterials m > 0) or matchPattern mn pattern:"baseobsmat_*"
        )
    ),

    fn sameColor a b =
    (
        (abs(a.r - b.r) < 0.01 and abs(a.g - b.g) < 0.01 and abs(a.b - b.b) < 0.01)
    ),

    fn checkUnits =
    (
        local detail = "display=" + (asText units.DisplayType) + ", systemScale=" + (asText units.SystemScale) + ", systemType=" + (asText units.SystemType)
        local ok = false
        try
        (
            ok = (abs(units.SystemScale - 1.0) < 0.0001 and units.SystemType == #inches and units.DisplayType == #generic)
        )
        catch(ok = false)
        add (if ok then "通过" else "不通过") "MAX单位" "场景" detail "标准：显示单位为通用单位，系统单位为 1 Unit = 1.0 Inches。"
    ),

    fn checkBaseImport =
    (
        try(refreshImportedBaseState())catch()
        local bodies = getBodyNodes()

        if bodies.count == 0 then
        (
            add "不通过" "基础体观察" "v_body" "未找到小写 v_body 作为模型节点。" "最终模型节点命名为 v_body。"
            return false
        )

        add "通过" "基础体观察" "v_body" ("当前生产模型节点数量=" + (bodies.count as string)) "基础体只用于导入场景观察，不参与尺寸对比。"

        if importedBaseNodes.count == 0 then
        (
            add "通过" "基础体观察" "基础体" "尚未导入基础体，已跳过观察项。" "如需观察，可点击“导入基础体观察”。"
            return true
        )

        add "通过" "基础体观察" "基础体" ("已导入基础体对象数=" + (importedBaseNodes.count as string)) "请在视口中观察基础体与当前模型。"
        true
    ),

    fn checkGeometry =
    (
        local nodes = getGeometryNodes()
        if nodes.count == 0 do
        (
            add "不通过" "几何" "场景" "未找到几何对象。" "场景应只保留最终模型几何。"
            return false
        )

        for n in nodes do
        (
            add (if n.name == "v_body" then "通过" else "不通过") "节点命名" n.name "几何节点命名检查。" "最终模型名必须是小写 v_body。"

            local hiddenState = false
            try(hiddenState = n.isHidden)catch(try(hiddenState = isHidden n)catch(hiddenState = false))
            add (if not hiddenState then "通过" else "不通过") "显示状态" n.name ("隐藏=" + (hiddenState as string)) "模型应保持显示状态, 不隐藏。"

            local wireOk = false
            try(wireOk = sameColor n.wirecolor (color 0 0 0))catch(wireOk = false)
            add (if wireOk then "通过" else "不通过") "线框颜色" n.name ("当前=" + (n.wirecolor as string)) "模型线框颜色应为黑色。"

            add (if classOf n.baseObject == Editable_Poly and n.modifiers.count == 0 then "通过" else "不通过") "对象类型" n.name ("baseObject=" + ((classOf n.baseObject) as string) + "；剩余修改器=" + (n.modifiers.count as string)) "先 Reset XForm，再塌陷为 Editable Poly。"

            local ng = countNgons n
            if ng == undefined then
                addRuntimeError ("多边面 / " + n.name) "读取 Editable Poly 面数据失败。"
            else
                add (if ng == 0 then "通过" else "不通过") "多边面" n.name ("大于4边的面数=" + (ng as string)) "修正大于4边的面。"

            local mr = meshReport n
            if mr[5] != "" then
                addRuntimeError ("网格检查 / " + n.name) mr[5]
            else
            (
                add (if mr[1] == 0 then "通过" else "不通过") "废点" n.name ("废点数=" + (mr[1] as string)) "清理孤立点。"
                add (if mr[2] == 0 then "通过" else "不通过") "废面" n.name ("零面积面数=" + (mr[2] as string)) "清理零面积面。"
                add (if mr[3] == 0 then "通过" else "不通过") "光滑组" n.name ("非1光滑组面数=" + (mr[3] as string)) "所有面设为光滑组 1。"
            )

            add (if transformIsClean n then "通过" else "不通过") "变换" n.name ("位置=" + (asText n.pos) + ", 旋转=" + (asText n.rotation) + ", 缩放=" + (asText n.scale)) "Reset XForm，折叠为 Editable Poly，并归零坐标。"
            add (if distance n.pos [0,0,0] <= 0.001 then "通过" else "不通过") "位置坐标" n.name ("Position=" + (asText n.pos)) "模型位置坐标应归零为 [0,0,0]；模型整体移动到世界原点。"

        )
    ),

    fn checkSceneExtras =
    (
        local camCount = (for n in cameras where isProductionNode n collect n).count
        local lightCount = (for n in lights where isProductionNode n collect n).count
        local helperCount = (for n in helpers where isProductionNode n and not isGroupedNode n collect n).count
        local boneCount = (likelyBoneNodes()).count
        local animCount = (animatedNodes()).count
        local groupCount = (groupedNodes()).count

        add (if camCount == 0 then "通过" else "不通过") "多余摄像机" "场景" ("摄像机数量=" + (camCount as string)) "删除摄像机。"
        add (if lightCount == 0 then "通过" else "不通过") "多余灯光" "场景" ("灯光数量=" + (lightCount as string)) "删除灯光。"
        add (if helperCount == 0 then "通过" else "不通过") "多余辅助对象" "场景" ("辅助对象数量=" + (helperCount as string)) "删除多余辅助对象。"
        add "通过" "组对象" "场景" ("组头/组成员数量=" + (groupCount as string)) "组结构会被保留，不参与多余辅助对象删除。"
        add (if boneCount == 0 then "通过" else "不通过") "多余骨骼" "场景" ("骨骼/二足节点数量=" + (boneCount as string)) "如无需要，删除骨骼。"
        add (if animCount == 0 then "通过" else "不通过") "动画信息" "场景" ("有动画的节点数量=" + (animCount as string)) "删除动画关键帧与控制器。"
    ),

    fn bitmapCoordsOk b =
    (
        local ok = true
        if b == undefined then return false
        try(if classOf b != Bitmaptexture do ok = false)catch(ok = false)
        try(if b.coords.showMapOnBack != true do ok = false)catch(ok = false)
        try(if b.coords.realWorldScale != false do ok = false)catch(ok = false)
        try(if b.coords.mapChannel != 1 do ok = false)catch(ok = false)
        try(if abs(b.coords.U_Offset) > 0.0001 do ok = false)catch(ok = false)
        try(if abs(b.coords.V_Offset) > 0.0001 do ok = false)catch(ok = false)
        try(if abs(b.coords.U_Tiling - 1.0) > 0.0001 do ok = false)catch(ok = false)
        try(if abs(b.coords.V_Tiling - 1.0) > 0.0001 do ok = false)catch(ok = false)
        try(if b.coords.U_Mirror != false do ok = false)catch(ok = false)
        try(if b.coords.V_Mirror != false do ok = false)catch(ok = false)
        try(if b.coords.U_Tile != true do ok = false)catch(ok = false)
        try(if b.coords.V_Tile != true do ok = false)catch(ok = false)
        ok
    ),

    fn diffuseBitmapOutputOk b =
    (
        local ok = true
        if b == undefined then return false
        try(if classOf b != Bitmaptexture do ok = false)catch(ok = false)
        try(if b.monoOutput != 0 do ok = false)catch(ok = false)
        try(if b.RGBOutput != 0 do ok = false)catch(ok = false)
        try(if b.alphasource != 2 do ok = false)catch(ok = false)
        try(if b.preMultAlpha != false do ok = false)catch(ok = false)
        ok
    ),

    fn opacityBitmapOutputOk b =
    (
        local ok = true
        if b == undefined then return false
        try(if classOf b != Bitmaptexture do ok = false)catch(ok = false)
        try(if b.monoOutput != 1 do ok = false)catch(ok = false)
        try(if b.RGBOutput != 1 do ok = false)catch(ok = false)
        try(if b.alphasource != 0 do ok = false)catch(ok = false)
        try(if b.preMultAlpha != true do ok = false)catch(ok = false)
        ok
    ),

    fn resolvedTexturePathForBitmap b =
    (
        local fnm = ""
        local resolved = ""
        try(fnm = asText b.filename)catch(fnm = "")
        if fnm == "" then return ""
        try(resolved = resolveTextureSource fnm)catch(resolved = "")
        if resolved != "" then return resolved
        if doesFileExist fnm then return fnm
        if (toLower (getFilenameType fnm)) == ".tga" then fnm else ""
    ),

    fn readBinaryFileBytes filePath maxBytes =
    (
        local bytes = #()
        local limit = maxBytes

        if filePath == undefined then return undefined
        if filePath == "" then return undefined
        if limit == undefined or limit <= 0 do limit = 18

        try
        (
            local dotNetBytes = (dotNetClass "System.IO.File").ReadAllBytes filePath
            if dotNetBytes != undefined do
            (
                limit = amin limit dotNetBytes.Length
                for i = 0 to (limit - 1) do
                    append bytes ((dotNetBytes.GetValue i) as integer)
                if bytes.count > 0 do return bytes
            )
        )
        catch()

        try
        (
            local fh = fopen filePath "rb"
            if fh != undefined do
            (
                for i = 1 to limit do
                (
                    local byteValue = undefined
                    try(byteValue = readByte fh #unsigned)catch(byteValue = undefined)
                    if byteValue != undefined do append bytes byteValue
                )
                try(fclose fh)catch(try(close fh)catch())
            )
        )
        catch()
        if bytes.count > 0 then bytes else undefined
    ),

    fn tgaAlphaState filePath =
    (
        local state = -1
        local sourcePath = ""
        local bitmapInfo = undefined
        if filePath == undefined then return -1
        if filePath == "" then return -1
        sourcePath = asText filePath
        if (toLower (getFilenameType sourcePath)) != ".tga" then return -1

        try(sourcePath = resolveTextureSource sourcePath)catch(sourcePath = "")
        if sourcePath == "" do sourcePath = asText filePath

        try(bitmapInfo = getBitmapInfo sourcePath)catch(bitmapInfo = undefined)
        if bitmapInfo != undefined do
        (
            try
            (
                if bitmapInfo.count >= 9 do
                (
                    if bitmapInfo[9] == true then
                        return 1
                )
            )
            catch()
        )

        local bytes = undefined
        try(bytes = readBinaryFileBytes sourcePath 18)catch(bytes = undefined)
        if bytes == undefined then return -1
        if bytes.count < 18 then return -1
        if findItem #(1,2,3,9,10,11) bytes[3] == 0 then return -1
        try
        (
            local colorMapType = bytes[2]
            local colorMapEntrySize = bytes[8]
            local pixelDepth = bytes[17]
            local descriptor = bytes[18]
            local alphaBits = descriptor - (((descriptor / 16) as integer) * 16)
            state = 0
            if alphaBits > 0 do state = 1
            if pixelDepth == 32 do state = 1
            if ((colorMapType == 1) and (colorMapEntrySize > 24)) do state = 1
        )
        catch(state = -1)
        state
    ),

    fn tgaFileHasAlpha filePath =
    (
        (tgaAlphaState filePath) == 1
    ),

    fn tgaFileAlphaReadable filePath =
    (
        (tgaAlphaState filePath) >= 0
    ),

    fn bitmapFilesMatch a b =
    (
        local af = ""
        local bf = ""
        if a == undefined then return false
        if b == undefined then return false
        try(af = toLower (filenameFromPath (asText a.filename)))catch(af = "")
        try(bf = toLower (filenameFromPath (asText b.filename)))catch(bf = "")
        if af == "" then return false
        af == bf
    ),

    fn isDefaultScanlineRendererValue r =
    (
        local rendererName = ""
        local defaultName = ""
        local ok = false
        if r == undefined then return false
        try(rendererName = toLower (classOf r as string))catch(rendererName = "")
        try(defaultName = toLower (classOf (Default_Scanline_Renderer()) as string))catch(defaultName = "")
        if rendererName != "" do
        (
            if findString rendererName "scanline" != undefined do ok = true
            if defaultName != "" and rendererName == defaultName do ok = true
        )
        ok
    ),

    fn isBitmapTex v =
    (
        local ok = false
        try(ok = (v != undefined and classOf v == Bitmaptexture))catch(ok = false)
        ok
    ),

    fn checkMaterials =
    (
        local sceneMats = #()
        local prodMats = #()
        local prodTree = #()
        local obsMats = #()
        local extraMats = #()
        local maps = #()
        local prodNodes = #()
        local materialNodes = #()
        local missingMaterialNodes = #()
        local knownMaps = #()
        local fallbackMaps = #()
        local prodMatInfo = ""

        try(sceneMats = scenematerials as array)catch(sceneMats = #())
        try(prodMats = productionMaterials())catch(prodMats = #())
        try(prodTree = productionMaterialTree())catch(prodTree = #())
        try(obsMats = baseMaterials())catch(obsMats = #())
        try(prodNodes = getGeometryNodes())catch(prodNodes = #())
        try(materialNodes = getMaterialNodes())catch(materialNodes = #())

        if prodMats.count == 0 do
        (
            for n in materialNodes where isValidNode n do
            (
                local nm = undefined
                try(nm = n.material)catch(nm = undefined)
                if nm != undefined do append prodMats nm
            )
            prodMats = makeUniqueArray prodMats
        )

        if ((prodTree.count == 0) and (prodMats.count > 0)) do
        (
            for m in prodMats where m != undefined do
            (
                local childTree = #()
                try(childTree = collectMaterialTree m)catch(childTree = #(m))
                if childTree.count == 0 do append childTree m
                join prodTree childTree
            )
            prodTree = makeUniqueArray prodTree
        )

        for n in prodNodes where isValidNode n do
        (
            local nm = undefined
            try(nm = n.material)catch(nm = undefined)
            if nm == undefined do append missingMaterialNodes n
        )

        add (if prodNodes.count > 0 then "通过" else "不通过") "生产模型" "场景" ("生产模型数量=" + (prodNodes.count as string)) "贴图材质检查需要当前场景存在生产模型。"
        add (if ((materialNodes.count > 0) and (missingMaterialNodes.count == 0)) then "通过" else "不通过") "材质拾取" "场景" ("有材质物体=" + (materialNodes.count as string) + ", 未拾取材质物体=" + (missingMaterialNodes.count as string)) "清空材质编辑器后，应从每个物件重新拾取材质球。"

        for n in missingMaterialNodes where isValidNode n do
        (
            add "不通过" "材质拾取" (asText n.name) "该物体没有材质球。" "请给每个生产模型物体拾取材质球。"
        )

        if prodNodes.count == 0 do
        (
            add "不通过" "材质数量" "场景" "当前没有生产模型。" "请确认场景中存在需要检查的生产模型。"
            return false
        )

        if prodMats.count == 0 do
        (
            add "不通过" "材质数量" "场景" "当前生产模型没有可检查的材质球。" "请确认每个生产模型都已拾取材质球；删除模型后这里必须重新报错。"
            return false
        )

        if prodTree.count == 0 do
        (
            prodTree = prodMats
            add "不通过" "材质数量" "场景" "材质树展开失败，已改为检查物体顶层材质。" "请继续查看下面逐项检查结果；如仍异常，重新拾取物体材质球。"
        )

        for m in sceneMats do
        (
            if m != undefined and not isBaseMaterial m do
            (
                if findItem prodTree m == 0 and findItem prodMats m == 0 and findItem obsMats m == 0 do append extraMats m
            )
        )

        add (if extraMats.count == 0 then "通过" else "不通过") "材质数量" "场景" ("场景材质=" + (sceneMats.count as string) + ", 生产材质=" + (prodTree.count as string) + ", 基础体材质=" + (obsMats.count as string) + ", 多余=" + (extraMats.count as string)) "清空材质编辑器后，从当前物体重新拾取材质球。"

        for m in prodTree do
        (
            if m != undefined and not isBaseMaterial m do
            (
                local mn = ""
                local bad = false
                local materialClass = ""
                local subCount = 0
                local isStandard = false
                local twoSidedOk = true
                local selfIllumOk = true
                local diffMap = undefined
                local opaMap = undefined
                local diffName = ""
                local opaName = ""
                local diffStem = ""
                local nameOk = true
                local diffPath = ""
                local diffAlphaState = -1
                local diffHasAlpha = false
                local diffAlphaReadable = false
                local opacityEnabled = false
                local opacityRuleOk = true
                local opacityDetail = ""

                try(mn = asText m.name)catch(mn = "")
                if mn == "" do mn = "未命名材质"
                try(bad = matchPattern mn pattern:"Material #*" ignoreCase:true)catch(bad = false)
                try(materialClass = (classOf m as string))catch(materialClass = "未知")
                try(subCount = getNumSubMtls m)catch(subCount = 0)
                try(isStandard = matchPattern materialClass pattern:"*standard*" ignoreCase:true)catch(isStandard = false)
                try(twoSidedOk = (m.twoSided == true))catch(twoSidedOk = isStandard)
                try(selfIllumOk = ((abs(m.selfIllumAmount - 100.0) <= 0.001) and not m.useSelfIllumColor))catch(selfIllumOk = isStandard)
                try(diffMap = m.diffuseMap)catch(diffMap = undefined)
                try(opaMap = m.opacityMap)catch(opaMap = undefined)
                if (isBitmapTex diffMap) do
                (
                    try(diffName = asText diffMap.filename)catch(diffName = "")
                    diffStem = toLower (getFilenameFile (filenameFromPath diffName))
                    if diffStem != "" do nameOk = ((toLower mn) == diffStem)
                    diffPath = resolvedTexturePathForBitmap diffMap
                    diffAlphaState = tgaAlphaState diffPath
                    diffAlphaReadable = (diffAlphaState >= 0)
                    diffHasAlpha = (diffAlphaState == 1)
                )
                if (isBitmapTex opaMap) do try(opaName = asText opaMap.filename)catch(opaName = "")
                try(opacityEnabled = (m.opacityMapEnable == true))catch(opacityEnabled = (opaMap != undefined))

                add (if isStandard then "通过" else "不通过") "材质类型" mn ("类型=" + materialClass) "材质球都应为 Standard。"
                add (if subCount == 0 then "通过" else "不通过") "材质层级" mn ("子材质数量=" + (subCount as string)) "材质球不能有多维子物体。"
                add (if bad then "不通过" else "通过") "材质命名" mn "检查默认材质名。" "材质球命名应使用颜色贴图的命名。"
                if diffStem != "" do
                    add (if nameOk then "通过" else "不通过") "材质命名" mn ("颜色贴图=" + diffName) "材质球命名应等于颜色贴图文件名。"
                add (if twoSidedOk and selfIllumOk then "通过" else "不通过") "材质参数" mn ("双面=" + (twoSidedOk as string) + ", 自发光100=" + (selfIllumOk as string)) "材质球需要勾选双面，自发光数值默认为100。"

                if (isBitmapTex diffMap) then
                (
                    add (if bitmapCoordsOk diffMap then "通过" else "不通过") "颜色贴图设置" diffName "坐标与显示参数检查。" "颜色贴图应按图示设置，且不能与透明贴图设置实例。"
                    add (if diffuseBitmapOutputOk diffMap then "通过" else "不通过") "颜色贴图输出" diffName "RGB/Alpha 输出设置检查。" "颜色贴图应使用 RGB 输出，Alpha 来源为无。"
                )
                else
                    add "不通过" "颜色贴图" mn "未找到颜色 Bitmap 贴图。" "每个生产材质球应拾取颜色贴图。"

                if (isBitmapTex opaMap) do
                (
                    add (if bitmapCoordsOk opaMap then "通过" else "不通过") "透明贴图设置" opaName "坐标与显示参数检查。" "透明贴图应按图示设置。"
                    add (if opacityBitmapOutputOk opaMap then "通过" else "不通过") "透明贴图输出" opaName "RGB/Alpha 输出设置检查。" "透明贴图应读取图像 Alpha，并以 Alpha 输出。"
                    if ((isBitmapTex diffMap) and (opaMap == diffMap)) do
                        add "不通过" "贴图实例" mn "颜色贴图和透明贴图共用了同一个 BitmapTexture。" "颜色贴图和透明贴图不能实例。"
                )

                if (isBitmapTex diffMap) do
                (
                    if (toLower (getFilenameType diffName)) == ".tga" do
                    (
                        local hasOpacityBitmap = false
                        if isBitmapTex opaMap do hasOpacityBitmap = true

                        if not diffAlphaReadable then
                        (
                            opacityRuleOk = false
                            opacityDetail = "TGA Alpha=无法读取贴图, 透明贴图=" + opaName + ", 贴图路径=" + diffName
                            add "不通过" "贴图读取" diffName "无法读取 TGA 文件，不能判定是否带 Alpha。" "请确认贴图文件存在于当前 MAX 资源目录、MAX 文件夹或贴图搜索路径中。"
                        )
                        else
                        (
                            if diffHasAlpha then
                            (
                                opacityRuleOk = hasOpacityBitmap
                                if not opacityEnabled do opacityRuleOk = false
                                if opaMap == diffMap do opacityRuleOk = false
                                if not (bitmapFilesMatch diffMap opaMap) do opacityRuleOk = false
                                if not (opacityBitmapOutputOk opaMap) do opacityRuleOk = false
                                opacityDetail = "TGA Alpha=true, 透明贴图=" + opaName + ", 启用=" + (opacityEnabled as string)
                            )
                            else
                            (
                                opacityRuleOk = not hasOpacityBitmap
                                if opacityEnabled do opacityRuleOk = false
                                opacityDetail = "TGA Alpha=false, 透明贴图=" + opaName + ", 启用=" + (opacityEnabled as string)
                            )
                        )

                        add (if opacityRuleOk then "通过" else "不通过") "透明贴图规则" mn opacityDetail "TGA 带 Alpha 时透明贴图应复制颜色贴图；TGA 不带 Alpha 时透明贴图应为空。"
                    )
                )
            )
        )

        maps = #()
        for m in prodTree where m != undefined do
        (
            try(join maps (collectBitmapTexturesRecursive m #()))catch()
        )
        maps = makeUniqueArray maps
        if maps.count == 0 do add "不通过" "贴图槽" "生产模型" "没有实际引用的 Bitmap 贴图。" "请给模型指定颜色 TGA。"

        for b in maps where b != undefined do
        (
            local fnm = ""
            local ext = ""
            try(fnm = asText b.filename)catch(fnm = "")
            ext = toLower (getFilenameType fnm)
            add (if ext == ".tga" and (resolveTextureSource fnm) != "" then "通过" else "不通过") "贴图格式" fnm ("扩展名=" + ext) "MAX 材质应统一使用 TGA。"
        )
    ),

    fn checkEnvironment =
    (
        local bgOk = sameColor backgroundColor (color 127 127 127)
        local ambOk = sameColor ambientColor (color 0 0 0)
        local tintVal = color 0 0 0
        local tintOk = false
        try
        (
            tintVal = lightTintColor
            tintOk = sameColor tintVal (color 255 255 255)
        )
        catch(tintOk = false)
        add (if bgOk then "通过" else "不通过") "环境背景" "场景" ("当前=" + (backgroundColor as string)) "标准：background = (color 127 127 127)。"
        add (if ambOk then "通过" else "不通过") "环境光" "场景" ("当前=" + (ambientColor as string)) "标准：ambient = (color 0 0 0)。"
        add (if tintOk then "通过" else "不通过") "环境染色" "场景" ("当前=" + (tintVal as string)) "标准：染色 = (color 255 255 255)。"
    ),

    fn checkRenderAndGammaSettings =
    (
        local gammaOk = true
        local gammaDetail = ""
        local rendererOk = false
        local renderTypeOk = true
        local rendererName = ""
        local currentType = ""
        try(if IDisplayGamma.enabled == true do gammaOk = false)catch()
        try(if IDisplayGamma.enable == true do gammaOk = false)catch()
        try(if gammaMgr.enabled == true do gammaOk = false)catch(try(if gammaMgr.enable == true do gammaOk = false)catch())
        gammaDetail = "Gamma/LUT启用=" + ((not gammaOk) as string)
        add (if gammaOk then "通过" else "不通过") "Gamma/LUT" "场景" gammaDetail "Gamma 和 LUT 应关闭。"

        try(rendererName = (classOf renderers.production as string))catch(rendererName = "未知")
        try(rendererOk = isDefaultScanlineRendererValue renderers.production)catch(rendererOk = false)
        try(currentType = renderType as string)catch(currentType = "未知")
        try(renderTypeOk = (renderType == #view or renderType == #normal))catch(renderTypeOk = true)
        add (if rendererOk then "通过" else "不通过") "渲染器设置" "场景" ("渲染器=" + rendererName + ", 类型=" + currentType) "只检查生产渲染器是否为默认扫描线；渲染尺寸不检查，渲染类型只显示。"
    ),

    fn fixEnvironment =
    (
        try(backgroundColor = (color 127 127 127))catch()
        try(ambientColor = (color 0 0 0))catch()
        try(lightTintColor = (color 255 255 255))catch()
    ),

    fn setBackfaceCull state =
    (
        /*
            Max 2015 的对象属性在不同安装/语言环境下可能显示为
            backfaceCull 或 backfacecull，两个名字都尝试，单个对象失败
            不影响其他对象。
        */
        for n in getGeometryNodes() where isValidNode n do
        (
            try(n.backfaceCull = state)catch(try(n.backfacecull = state)catch())
        )
        true
    ),

    fn fixDisplaySettings =
    (
        /* 生产模型统一使用纯黑线框；基础体观察对象不在这里改色。 */
        for n in getGeometryNodes() where isValidNode n do
        (
            try(n.wirecolor = (color 0 0 0))catch()
        )
        true
    ),

    fn fixGammaSettings =
    (
        /* 关闭 Gamma/LUT 修正，属性不存在时静默跳过，兼容 Max 2015。 */
        try(IDisplayGamma.colorCorrectionMode = #none)catch()
        try(IDisplayGamma.colorCorrectionPrefMode = #none)catch()
        try(IDisplayGamma.enabled = false)catch()
        try(IDisplayGamma.enable = false)catch()
        try(gammaMgr.enabled = false)catch(try(gammaMgr.enable = false)catch())
        true
    ),

    fn fixProductRenderMode =
    (
        /*
            使用产品级渲染模式，不使用迭代渲染。
            Max 版本或渲染器不支持该属性时静默跳过，不切换 ActiveShade。
        */
        try(maxOps.rendUseIterative = false)catch()
        true
    ),

    fn fixRenderSettings =
    (
        /*
            按交付参考图设置默认扫描线渲染器、视图区域和 区域 / 1.5。
            不修改用户当前渲染宽高；不同渲染器版本的属性名用 try/catch 兼容。
        */
        local scanline = undefined
        try(renderers.production = Default_Scanline_Renderer())catch()
        try(scanline = renderers.production)catch()
        try(renderers.current = renderers.production)catch()

        try(renderPixelAspect = 1.0)catch()
        try(renderType = #view)catch()

        if scanline != undefined do
        (
            try(scanline.mapping = true)catch()
            try(scanline.shadows = true)catch()
            try(scanline.autoReflect = true)catch()
            try(scanline.forceWireframe = false)catch()
            try(scanline.enableSSE = false)catch()
            try(scanline.antialiasing = true)catch()
            try(scanline.filterMaps = true)catch()
            try(scanline.antiAliasFilter = Area())catch()
            try(scanline.antiAliasFilterSize = 1.5)catch()
            try(scanline.globalSamplerEnabled = false)catch()
            try(scanline.enablePixelSampler = true)catch()
            try(scanline.globalSamplerSampleMaps = true)catch()
        )
        true
    ),

    fn fixUnits =
    (
        try
        (
            units.SystemScale = 1.0
            units.SystemType = #inches
            units.DisplayType = #generic
        )
        catch()
    ),

    fn fixNormalsAndReset =
    (
        for n in getGeometryNodes() do
        (
            try
            (
                local m = Edit_Normals()
                addModifier n m
                local en = m.EditNormalsMod
                local count = en.GetNumNormals node:n
                if count > 0 do en.Reset selection:#{1..count} node:n
                collapseStack n
            )catch(addRuntimeError n.name (exceptionText "重置法线失败"))
        )
    ),

    fn collectMaterialTree m =
    (
        local out = #()
        if m != undefined do
        (
            append out m
            try
            (
                local subCount = getNumSubMtls m
                for i = 1 to subCount do
                (
                    join out (collectMaterialTree (getSubMtl m i))
                )
            )
            catch()
        )
        makeUniqueArray out
    ),

    fn productionMaterialTree =
    (
        local out = #()
        for m in productionMaterials() do join out (collectMaterialTree m)
        makeUniqueArray out
    ),

    fn setupBitmapCoords b =
    (
        if b == undefined then return false
        try(b.coords.showMapOnBack = true)catch()
        try(b.coords.realWorldScale = false)catch()
        try(b.coords.mapChannel = 1)catch()
        try(b.coords.U_Offset = 0.0)catch()
        try(b.coords.V_Offset = 0.0)catch()
        try(b.coords.U_Tiling = 1.0)catch()
        try(b.coords.V_Tiling = 1.0)catch()
        try(b.coords.U_Mirror = false)catch()
        try(b.coords.V_Mirror = false)catch()
        try(b.coords.U_Tile = true)catch()
        try(b.coords.V_Tile = true)catch()
        true
    ),

    fn setupDiffuseBitmap b =
    (
        if b == undefined then return false
        setupBitmapCoords b
        try(b.monoOutput = 0)catch()    -- RGB 强度
        try(b.RGBOutput = 0)catch()     -- RGB
        try(b.alphasource = 2)catch()   -- 无，不透明
        try(b.preMultAlpha = false)catch() -- DDS RGB 保持直通，不用 Alpha 预乘
        true
    ),

    fn setupOpacityBitmap b =
    (
        if b == undefined then return false
        setupBitmapCoords b
        try(b.monoOutput = 1)catch()    -- Alpha
        try(b.RGBOutput = 1)catch()     -- Alpha 作为灰度
        try(b.alphasource = 0)catch()   -- 图像 Alpha
        try(b.preMultAlpha = true)catch() -- 按思维导图透明贴图截图启用预乘 Alpha
        true
    ),

    fn materialIsPlainStandard m =
    (
        local materialClass = ""
        local subCount = 0
        local ok = false
        if m == undefined then return false
        try(materialClass = classOf m as string)catch(materialClass = "")
        try(subCount = getNumSubMtls m)catch(subCount = 0)
        if materialClass != "" do
        (
            if matchPattern materialClass pattern:"*standard*" ignoreCase:true do ok = true
        )
        if subCount != 0 do ok = false
        ok
    ),

    fn materialHasDiffuseBitmap m =
    (
        local diffMap = undefined
        if m == undefined then return false
        try(diffMap = m.diffuseMap)catch(diffMap = undefined)
        isBitmapTex diffMap
    ),

    fn preferredPlainMaterialSource m =
    (
        local tree = #()
        local chosen = undefined
        if m == undefined then return undefined
        try(tree = collectMaterialTree m)catch(tree = #(m))

        for item in tree where chosen == undefined do
        (
            if ((materialIsPlainStandard item) and (materialHasDiffuseBitmap item)) do chosen = item
        )
        for item in tree where chosen == undefined do
        (
            if materialHasDiffuseBitmap item do chosen = item
        )
        for item in tree where chosen == undefined do
        (
            if materialIsPlainStandard item do chosen = item
        )
        if chosen == undefined do chosen = m
        chosen
    ),

    fn standardMaterialFromSource src =
    (
        local out = undefined
        local diffMap = undefined
        local opaMap = undefined
        if src == undefined then return undefined
        if materialIsPlainStandard src then return src
        try(out = standardMaterial())catch(out = undefined)
        if out == undefined then return undefined

        try(out.name = asText src.name)catch()
        try(out.twoSided = true)catch()
        try(out.useSelfIllumColor = false)catch()
        try(out.selfIllumAmount = 100.0)catch()

        try(diffMap = src.diffuseMap)catch(diffMap = undefined)
        try(opaMap = src.opacityMap)catch(opaMap = undefined)
        if diffMap != undefined do
        (
            try(out.diffuseMap = diffMap)catch()
            try(out.diffuseMapEnable = true)catch()
        )
        if opaMap != undefined do
        (
            try(out.opacityMap = opaMap)catch()
            try(out.opacityMapEnable = true)catch()
        )
        out
    ),

    fn normalizeProductionNodeMaterials =
    (
        collapseShellMaterials()
        for n in getMaterialNodes() do
        (
            try
            (
                local oldMat = n.material
                if not materialIsPlainStandard oldMat do
                (
                    local count = getNumSubMtls oldMat
                    if count > 0 then
                        addRuntimeError n.name "包含子材质；请按实际使用的材质分离物件后再修复，已保留原外观。"
                    else
                    (
                        local newMat = standardMaterialFromSource oldMat
                        if newMat == undefined then throw "不能无损读取原材质"
                        else n.material = newMat
                    )
                )
            )catch(addRuntimeError n.name (exceptionText "材质标准化失败"))
        )
    ),

    fn materialBitmapTextures m =
    (
        local texs = #()
        try(texs = collectBitmapTexturesRecursive m #())catch(texs = #())
        try(join texs (getClassInstances Bitmaptexture target:m))catch()
        makeUniqueArray texs
    ),

    fn collectTextureDirsFromMaps maps =
    (
        local out = #()
        for b in maps do
        (
            local fileName = ""
            local dirName = ""
            try(fileName = asText b.filename)catch(fileName = "")
            try(dirName = getFilenamePath fileName)catch(dirName = "")
            if dirName != "" do
            (
                dirName = toLower (trimTrailingPathSeparators dirName)
                if findItem out dirName == 0 do append out dirName
            )
        )
        out
    ),

    fn pruneUnusedTextureSearchPaths beforeMaps afterMaps =
    (
        local beforeDirs = collectTextureDirsFromMaps beforeMaps
        local afterDirs = collectTextureDirsFromMaps afterMaps
        for oldDir in beforeDirs do
        (
            if findItem afterDirs oldDir == 0 do
            (
                try(pathConfig.removePath oldDir)catch()
                try(pathConfig.removePath (oldDir + "\\"))catch()
            )
        )
    ),

    fn normalizeProductionMaterialNames =
    (
        for m in productionMaterialTree() where m != undefined do
        (
            local diffTex = undefined
            local texName = ""
            try(diffTex = m.diffuseMap)catch(diffTex = undefined)
            if isBitmapTex diffTex do
            (
                try(texName = asText diffTex.filename)catch(texName = "")
                local leaf = getFilenameFile (filenameFromPath texName)
                if leaf != "" do try(m.name = leaf)catch()
            )
        )
        true
    ),

    fn normalizeProductionTextureExtensionsToTga =
    (
        for t in bitmapTextures() do
        (
            local source = asText t.filename
            if source != "" and toLower (getFilenameType source) != ".tga" do
            (
                local candidate = (getFilenamePath source) + (getFilenameFile source) + ".tga"
                local actual = resolveTextureSource candidate
                if actual != "" then
                    try(t.filename = actual)catch(addRuntimeError "贴图格式" (exceptionText source))
                else addRuntimeError "贴图格式" ("未找到真实同名 TGA，已保留原引用：" + source)
            )
        )
        true
    ),

    fn stripProductionTexturePaths =
    (
        for b in bitmapTextures() do
        (
            local source = asText b.filename
            local actual = resolveTextureSource source
            if actual == "" then addRuntimeError "去贴图路径" ("源贴图不存在或同名歧义，已保留引用：" + source)
            else
            (
                try
                (
                    local folder = getFilenamePath actual
                    -- Keep bare filenames resolvable in the current Max session.
                    if (mapPaths.getFullFilePath (filenameFromPath actual)) == undefined or (mapPaths.getFullFilePath (filenameFromPath actual)) == "" do mapPaths.add folder
                    b.filename = filenameFromPath actual
                )catch(addRuntimeError "去贴图路径" (exceptionText source))
            )
        )
        true
    ),

    fn fixTexturePathsOnly = (stripProductionTexturePaths()),

    fn checkTexturePathsRemoved =
    (
        local maps = #()
        local knownMaps = #()
        try(maps = bitmapTextures())catch(maps = #())

        maps = makeUniqueArray maps
        if maps.count == 0 do
        (
            add "通过" "贴图路径" "场景" "未发现可处理的贴图路径。" "材质是否缺贴图由贴图材质检查负责。"
            return true
        )
        for b in maps do
        (
            local fnm = ""
            local leaf = ""
            local ok = false
            try(fnm = asText b.filename)catch(fnm = "")
            if fnm != "" do
            (
                leaf = filenameFromPath fnm
                ok = (leaf != "" and fnm == leaf)
            )
            add (if ok then "通过" else "不通过") "贴图路径" (if leaf != "" then leaf else fnm) ("当前=" + fnm) "贴图路径应只保留文件名，不保留磁盘路径。"
        )
        true
    ),

    fn fixMaterialSettings =
    (
        for m in productionMaterials() where materialIsPlainStandard m do
        (
            try
            (
                if not m.twoSided do m.twoSided = true
                if m.useSelfIllumColor do m.useSelfIllumColor = false
                if abs(m.selfIllumAmount - 100.0) > 0.001 do m.selfIllumAmount = 100.0
                local diff = m.diffuseMap
                if isBitmapTex diff then
                (
                    if not m.diffuseMapEnable do m.diffuseMapEnable = true
                    if not (bitmapCoordsOk diff and diffuseBitmapOutputOk diff) do setupDiffuseBitmap diff
                    local alpha = tgaAlphaState (resolvedTexturePathForBitmap diff)
                    if alpha == 1 then
                    (
                        local opa = m.opacityMap
                        if not isBitmapTex opa or opa == diff or not bitmapFilesMatch diff opa do
                        (
                            opa = copy diff
                            m.opacityMap = opa
                        )
                        if not (bitmapCoordsOk opa and opacityBitmapOutputOk opa) do setupOpacityBitmap opa
                        m.opacityMapEnable = true
                        m.opacityMapAmount = 100.0
                    )
                    else if alpha == 0 then
                    (
                        if m.opacityMap != undefined do m.opacityMap = undefined
                        m.opacityMapEnable = false
                    )
                    else addRuntimeError m.name "TGA Alpha 无法读取，未改变透明贴图。"
                )
                else addRuntimeError m.name "缺少颜色 Bitmap 贴图，请指定真实 TGA。"
            )catch(addRuntimeError m.name (exceptionText "材质参数修改失败"))
        )
    ),

    fn clearMaterialEditorSlots =
    (
        local slotCount = 24
        local resetOk = false
        try(slotCount = meditMaterials.count)catch()
        for i = 1 to slotCount do
        (
            /*
                某些 3ds Max 版本不接受把材质编辑器槽直接赋值为
                undefined，旧材质会因此继续显示。先尝试真正清空；
                如果版本拒绝，再用全新的默认材质覆盖旧槽，确保旧
                材质引用不会残留。
            */
            resetOk = false
            try
            (
                meditMaterials[i] = undefined
                resetOk = (meditMaterials[i] == undefined)
            )
            catch()
            if not resetOk do
                try(meditMaterials[i] = standardMaterial())catch()
        )
        true
    ),

    fn syncMaterialEditorSlots =
    (
        local slotCount = 24
        try(slotCount = meditMaterials.count)catch()
        clearMaterialEditorSlots()
        /*
            从当前生产模型完整拾取材质树，包含 Multi/Sub-Object
            等嵌套子材质，而不是只写入几何对象的顶层材质。
        */
        local mats = productionMaterialTree()

        local idx = 1
        for m in mats do
        (
            if m != undefined and idx <= slotCount do
            (
                try(meditMaterials[idx] = m)catch()
                idx += 1
            )
        )
    ),

    fn collapseShellMaterialTree m =
    (
        if m == undefined then return undefined

        /*
            Render To Texture 会把原始材质和烘培材质同时保存在
            Shell_Material 中。交付模型只保留烘培后的材质；
            如果烘培材质不存在，才回退到原始材质。
        */
        local materialClass = ""
        try(materialClass = (classOf m as string))catch(materialClass = "")
        if matchPattern materialClass pattern:"*shell*" ignoreCase:true then
        (
            local baked = undefined
            local original = undefined
            try(baked = m.bakedMaterial)catch(baked = undefined)
            try(original = m.originalMaterial)catch(original = undefined)
            if baked != undefined then
                return collapseShellMaterialTree baked
            else
                return collapseShellMaterialTree original
        )

        local subCount = 0
        try(subCount = getNumSubMtls m)catch(subCount = 0)
        if subCount > 0 do
        (
            for i = 1 to subCount do
            (
                local child = undefined
                local replacement = undefined
                try(child = getSubMtl m i)catch(child = undefined)
                if child != undefined do
                (
                    replacement = collapseShellMaterialTree child
                    if replacement != undefined and replacement != child do
                        try(setSubMtl m i replacement)catch()
                )
            )
        )
        m
    ),

    fn collapseShellMaterials =
    (
        local changed = 0
        local oldPropagation = true
        local beforeMaps = #()
        local beforeDirs = #()
        local afterDirs = #()
        try(beforeMaps = bitmapTextures())catch(beforeMaps = #())
        for b in beforeMaps do
        (
            local fileName = ""
            local dirName = ""
            try(fileName = asText b.filename)catch(fileName = "")
            try(dirName = getFilenamePath fileName)catch(dirName = "")
            if dirName != "" do
            (
                dirName = toLower (trimTrailingPathSeparators dirName)
                if findItem beforeDirs dirName == 0 do append beforeDirs dirName
            )
        )
        try(oldPropagation = instancemgr.autoMtlPropagation)catch()
        try(instancemgr.autoMtlPropagation = false)catch()

        for n in getMaterialNodes() where isValidNode n do
        (
            local oldMaterial = undefined
            local newMaterial = undefined
            try(oldMaterial = n.material)catch(oldMaterial = undefined)
            if oldMaterial != undefined do
            (
                newMaterial = collapseShellMaterialTree oldMaterial
                if newMaterial != undefined and newMaterial != oldMaterial do
                (
                    try
                    (
                        n.material = newMaterial
                        changed += 1
                    )
                    catch()
                )
            )
        )

        try(instancemgr.autoMtlPropagation = oldPropagation)catch()

        /*
            Shell 拆除后，清理只属于原始材质的旧位图搜索路径。
            当前烘培材质仍使用的目录不会被移除；API 不存在时静默跳过，
            不影响材质本身已经完成的重链。
        */
        local afterMaps = #()
        try(afterMaps = bitmapTextures())catch(afterMaps = #())
        changed
    ),

    fn finalResetTransformAndCollapse =
    (
        for n in getGeometryNodes() do
        (
            try
            (
                if not transformIsClean n do
                (
                    ResetXForm n
                    collapseStack n
                )
                if n.modifiers.count > 0 or classOf n.baseObject != Editable_Poly do convertToPoly n
                if distance n.pos [0,0,0] > 0.001 do n.pos = [0,0,0]
            )catch(addRuntimeError n.name (exceptionText "归零或重置变换失败"))
        )
    ),

    fn fixMaterialsAndTextures =
    (
        normalizeProductionTextureExtensionsToTga()
        normalizeProductionMaterialNames()
        true
    ),

    fn fixGeometry =
    (
        for n in getGeometryNodes() do
        (
            try
            (
                if n.name != "v_body" do n.name = "v_body"
                if not sameColor n.wirecolor (color 0 0 0) do n.wirecolor = color 0 0 0
                if n.isHidden do unhide n
                if n.modifiers.count > 0 or classOf n.baseObject != Editable_Poly do convertToPoly n
                local mr = meshReport n
                if mr[1] > 0 do polyOp.deleteIsoVerts n
                if mr[3] > 0 do polyOp.setFaceSmoothGroup n #{1..(polyOp.getNumFaces n)} 1
            )catch(addRuntimeError n.name (exceptionText "模型修改失败"))
        )
    ),

    fn removeImportedBaseBody =
    (
        try(refreshImportedBaseState())catch()
        local baseMaterialTree = #()
        local baseMaps = #()
        local productionMaps = #()
        local productionDirs = #()
        local baseDirs = #()
        local productionMaterialsTree = #()
        local oldDir = ""
        local fileName = ""
        local dirName = ""
        local m = undefined

        try
        (
            for m in importedBaseMaterials where m != undefined do
                join baseMaterialTree (collectMaterialTree m)
            baseMaterialTree = makeUniqueArray baseMaterialTree
        )
        catch(baseMaterialTree = #())
        try(baseMaps = bitmapTexturesFromMaterialList importedBaseMaterials)catch(baseMaps = #())
        try(productionMaps = bitmapTextures())catch(productionMaps = #())
        try(productionMaterialsTree = productionMaterialTree())catch(productionMaterialsTree = #())

        if importedBaseNodes.count > 0 do
        (
            try(delete importedBaseNodes)catch()
        )

        /*
            删除基础体节点后，场景材质库和 Compact Material Editor 仍可能
            保留基础体材质引用。先清槽，再删除不被生产模型使用的基础体材质；
            共享材质会被保留，避免误伤最终模型。
        */
        try(clearMaterialEditorSlots())catch()
        for m in baseMaterialTree where m != undefined do
        (
            if findItem productionMaterialsTree m == 0 do
                try(deleteSceneMaterial m)catch()
        )

        importedBaseNodes = #()
        importedBaseMaterials = #()
        try(syncMaterialEditorSlots())catch()

        /*
            只移除基础体独占的旧搜索路径。生产贴图仍使用的目录不移除；
            这样不会因为清理基础体而让生产模型贴图失效。
        */
        pruneUnusedTextureSearchPaths baseMaps productionMaps
        true
    ),

    fn fixSceneExtras =
    (
        local toDelete = #()
        join toDelete (for n in cameras where isProductionNode n collect n)
        join toDelete (for n in lights where isProductionNode n collect n)
        join toDelete (for n in helpers where isProductionNode n and not isGroupedNode n collect n)
        join toDelete (likelyBoneNodes())
        for n in makeUniqueArray toDelete where isValidNode n do
            try(delete n)catch(addRuntimeError "场景清理" (exceptionText "删除对象失败"))
        for n in animatedNodes() do
        (
            try
            (
                deleteKeys n.position.controller #allKeys
                deleteKeys n.rotation.controller #allKeys
                deleteKeys n.scale.controller #allKeys
            )catch(addRuntimeError n.name (exceptionText "删除动画关键帧失败"))
        )
    ),

    fn runEnvironmentCheck =
    (
        try(refreshImportedBaseState())catch()
        resetReport()
        try(checkUnits())catch(addRuntimeError "MAX单位" "单位检查执行失败。")
        try(checkSceneExtras())catch(addRuntimeError "场景环境" "多余相机、灯光、辅助对象、骨骼或动画检查执行失败。")
        try(checkEnvironment())catch(addRuntimeError "环境" "环境背景、环境光或染色检查执行失败。")
        try(checkRenderAndGammaSettings())catch(addRuntimeError "渲染器设置" "Gamma/LUT 或渲染器设置检查执行失败。")
        appendFixErrors()
        report
    ),

    fn runModelCheck =
    (
        try(refreshImportedBaseState())catch()
        resetReport()
        try(checkGeometry())catch(addRuntimeError "模型" "模型检查执行失败。")
        appendFixErrors()
        report
    ),

    fn runMaterialCheck =
    (
        try(refreshImportedBaseState())catch()
        resetReport()
        try(checkMaterials())catch(addRuntimeError "贴图材质" "材质或贴图检查执行失败。")
        try(checkTexturePathsRemoved())catch(addRuntimeError "贴图路径" "贴图路径检查执行失败。")
        appendFixErrors()
        report
    ),

    fn fixEnvironmentOnly =
    (
        refreshImportedBaseState()
        if not beginFix() then return false
        undo "征服MAX 环境修改" on
        (
            try(fixUnits(); fixEnvironment(); fixGammaSettings(); fixProductRenderMode(); fixRenderSettings(); fixSceneExtras())
            catch(addRuntimeError "环境修改" (exceptionText "执行失败"))
        )
        endFix()
    ),

    fn fixModelOnly =
    (
        refreshImportedBaseState()
        if not beginFix() then return false
        undo off
        (
            try(fixNormalsAndReset(); fixGeometry(); finalResetTransformAndCollapse())
            catch(addRuntimeError "模型修改" (exceptionText "执行失败"))
        )
        clearUndoBuffer()
        endFix()
    ),

    fn fixMaterialOnly =
    (
        refreshImportedBaseState()
        if not beginFix() then return false
        undo "征服MAX 材质修改" on
        (
            try
            (
                normalizeProductionNodeMaterials()
                fixMaterialsAndTextures()
                fixMaterialSettings()
                syncMaterialEditorSlots()
                stripProductionTexturePaths()
                if fixErrors.count == 0 do saveCurrentScene()
            )catch(addRuntimeError "材质修改" (exceptionText "执行失败"))
        )
        endFix()
    ),

    fn autoFix deleteBaseBody =
    (
        refreshImportedBaseState()
        if not beginFix() then return false
        undo off
        (
            try(fixUnits(); fixEnvironment(); fixGammaSettings(); fixProductRenderMode(); fixRenderSettings())catch(addRuntimeError "环境" (exceptionText "失败"))
            try(fixNormalsAndReset(); fixGeometry(); finalResetTransformAndCollapse())catch(addRuntimeError "模型" (exceptionText "失败"))
            try(normalizeProductionNodeMaterials(); fixMaterialsAndTextures(); fixMaterialSettings(); syncMaterialEditorSlots(); stripProductionTexturePaths())catch(addRuntimeError "材质" (exceptionText "失败"))
            try(fixSceneExtras())catch(addRuntimeError "场景清理" (exceptionText "失败"))
            if deleteBaseBody do try(removeImportedBaseBody())catch(addRuntimeError "基础体" (exceptionText "失败"))
            if fixErrors.count == 0 do saveCurrentScene()
        )
        clearUndoBuffer()
        endFix()
    ),

    fn runAll =
    (
        try(refreshImportedBaseState())catch()
        resetReport()
        try(checkUnits())catch(addRuntimeError "MAX单位" "单位检查执行失败。")
        try(checkBaseImport())catch(addRuntimeError "基础体观察" "基础体观察检查执行失败。")
        try(checkGeometry())catch(addRuntimeError "几何" "几何检查执行失败。")
        try(checkSceneExtras())catch(addRuntimeError "场景清理" "摄像机、灯光、骨骼或动画检查执行失败。")
        try(checkMaterials())catch(addRuntimeError "材质与贴图" "材质或贴图检查执行失败。")
        try(checkTexturePathsRemoved())catch(addRuntimeError "贴图路径" "路径检查执行失败。")
        try(checkEnvironment())catch(addRuntimeError "环境" "环境检查执行失败。")
        try(checkRenderAndGammaSettings())catch(addRuntimeError "渲染器设置" "Gamma/LUT 或渲染器设置检查执行失败。")
        appendFixErrors()
        report
    ),

    fn compactShortText value maxChars =
    (
        local s = asText value
        if s.count > maxChars then
            (substring s 1 maxChars) + "..."
        else
            s
    ),

    fn compactTargetText targets itemCount =
    (
        local targetText = ""
        for t in targets do
        (
            if targetText == "" then
                targetText = asText t
            else
                targetText += "、" + (asText t)
        )
        if targets.count >= 4 do targetText += "等"
        if itemCount > 1 do targetText += "（" + (itemCount as string) + "项）"
        targetText
    ),

    fn compactReportText wantedStatus =
    (
        local groups = #()
        local result = ""

        for r in report where r.status == wantedStatus do
        (
            local groupIndex = 0
            for i = 1 to groups.count do
            (
                if groups[i][1] == r.category and groupIndex == 0 do
                    groupIndex = i
            )

            if groupIndex == 0 then
            (
                append groups #(r.category, 1, #(r.target), r.detail, r.suggestion)
            )
            else
            (
                groups[groupIndex][2] = groups[groupIndex][2] + 1
                local targets = groups[groupIndex][3]
                if findItem targets r.target == 0 and targets.count < 4 do
                    append targets r.target
                groups[groupIndex][3] = targets
                if groups[groupIndex][4] == "" do
                    groups[groupIndex][4] = r.detail
                if groups[groupIndex][5] == "" do
                    groups[groupIndex][5] = r.suggestion
            )
        )

        for g in groups do
        (
            local targetText = compactTargetText g[3] g[2]
            if wantedStatus == "通过" then
            (
                result += "MAX | 通过 | " + g[1] + " | " + targetText + "\r\n"
            )
            else
            (
                local actionText = asText g[5]
                if actionText == "" do actionText = "请根据检查项修正后重新检查。"
                if g[1] == "报错" do
                    actionText = (compactShortText g[4] 120) + "；" + actionText
                result += "MAX | " + wantedStatus + " | " + g[1] + " | " + targetText + " | " + actionText + "\r\n"
            )
        )
        result
    ),

    fn reportPassText =
    (
        compactReportText "通过"
    ),

    fn reportIssueText =
    (
        local text = ""
        for item in report where item.status != "通过" do
            text += "[" + item.category + "] " + item.target + "\r\n" + item.detail + "\r\n" + item.suggestion + "\r\n\r\n"
        if text == "" then "没有待处理问题。" else text
    ),

    fn textureFileStemEndsWithF value =
    (
        local leaf = ""
        local stem = ""
        local lowerStem = ""
        try(leaf = filenameFromPath (asText value))catch(leaf = "")
        if leaf == "" then return false
        try(stem = getFilenameFile leaf)catch(stem = "")
        lowerStem = toLower (asText stem)
        if lowerStem.count < 2 then
            false
        else
            (substring lowerStem (lowerStem.count - 1) 2) == "_f"
    ),

    fn interfaceNodeExcludedByTexture n =
    (
        local maps = #()
        local excluded = false
        if not isValidNode n then return false
        try
        (
            if n.material != undefined do
                maps = materialBitmapTextures n.material
        )
        catch(maps = #())
        for b in maps where b != undefined and not excluded do
        (
            local fileName = ""
            try(fileName = asText b.filename)catch(fileName = "")
            if textureFileStemEndsWithF fileName do
                excluded = true
        )
        excluded
    ),

    fn textureStemForNode n =
    (
        local stem = ""
        try
        (
            if isBitmapTex n.material.diffuseMap do stem = getFilenameFile n.material.diffuseMap.filename
        )catch()
        stem
    ),

    fn safeC3Stem value =
    (
        local s = asText value
        local invalidChars = #("\\", "/", ":", "*", "?", "<", ">", "|")
        for invalidChar in invalidChars do
            s = substituteString s invalidChar "_"
        while (s.count > 0 and ((substring s s.count 1) == "." or (substring s s.count 1) == " ")) do
            s = substring s 1 (s.count - 1)
        if s == "" then "object" else s
    ),

    fn c3ResourceRoot = (currentMaxResourceRoot()),

    fn outputResourceRoot = (currentMaxResourceRoot()),

    fn currentMaxStem =
    (
        local stem = ""
        try(stem = getFilenameFile maxFileName)catch(stem = "")
        if stem == "" do
        (
            local filePath = ""
            try(filePath = currentMaxFullPath())catch(filePath = "")
            if filePath != "" do stem = getFilenameFile filePath
        )
        if stem == "" then "未命名MAX" else safeC3Stem stem
    ),

    fn getNodesWorldBounds nodes =
    (
        local hasAny = false
        local mn = [0,0,0]
        local mx = [0,0,0]

        for n in nodes where isValidNode n do
        (
            local bbMin = undefined
            local bbMax = undefined
            try
            (
                /*
                    nodeGetBoundingBox returns coordinates in the matrix
                    supplied here. The render layout combines objects from
                    different local spaces, so the bounds must be collected
                    in one shared world space.
                */
                local bb = nodeGetBoundingBox n (matrix3 1)
                if bb != undefined do
                (
                    bbMin = bb[1]
                    bbMax = bb[2]
                )
            )
            catch
            (
                try
                (
                    bbMin = n.min
                    bbMax = n.max
                )
                catch()
            )
            if bbMin != undefined and bbMax != undefined do
            (
                if not hasAny then
                (
                    mn = bbMin
                    mx = bbMax
                    hasAny = true
                )
                else
                (
                    mn.x = amin mn.x bbMin.x
                    mn.y = amin mn.y bbMin.y
                    mn.z = amin mn.z bbMin.z
                    mx.x = amax mx.x bbMax.x
                    mx.y = amax mx.y bbMax.y
                    mx.z = amax mx.z bbMax.z
                )
            )
        )

        if hasAny then #(mn, mx, (mx - mn), ((mn + mx) / 2.0)) else undefined
    ),

    fn getEvaluatedNodesWorldBounds nodes =
    (
        local probes = #()
        local probeNodes = #()
        local result = undefined

        for n in nodes where isValidNode n do
        (
            local probe = undefined
            try(probe = snapshot n)catch(probe = undefined)
            if probe != undefined then
            (
                append probes probe
                append probeNodes probe
            )
            else
                append probeNodes n
        )

        result = getNodesWorldBounds probeNodes
        for probe in probes where isValidNode probe do
            try(delete probe)catch()
        result
    ),

    fn findTextureFileByLeaf root leaf =
    (
        local pending = #()
        local visited = #()
        local wanted = toLower (asText leaf)
        local found = ""
        if root == "" or wanted == "" or not doesDirectoryExist root then return ""
        append pending (trimTrailingPathSeparators root)

        while pending.count > 0 and found == "" do
        (
            local folder = pending[1]
            deleteItem pending 1
            if findItem visited folder == 0 do
            (
                append visited folder
                local files = #()
                local dirs = #()
                try(files = getFiles (folder + "\\*"))catch(files = #())
                for f in files where toLower (filenameFromPath f) == wanted do
                (
                    found = f
                    exit
                )
                if found == "" do
                (
                    try(dirs = getDirectories (folder + "\\*"))catch(dirs = #())
                    for d in dirs where findItem visited d == 0 do
                        if findItem pending d == 0 do append pending d
                )
            )
        )
        found
    ),

    fn resolveTextureSource value =
    (
        local source = asText value
        if source == "" then return ""
        -- Honor an existing explicit reference; never silently substitute a sibling asset.
        if (getFilenamePath source) != "" and doesFileExist source then return source
        local root = currentMaxResourceRoot()
        if root == "" then return ""
        local leaf = filenameFromPath source
        -- Prefer the current scene directory, then the standard delivery directory.
        -- Only fall back to the known 3d source folder, never arbitrary siblings.
        local currentFolder = getFilenamePath (currentMaxFullPath())
        local currentCandidate = currentFolder + leaf
        if doesFileExist currentCandidate then return currentCandidate
        local candidates = #(root + "\\MAX\\" + leaf, root + "\\" + leaf)
        local hits = for candidate in candidates where doesFileExist candidate collect candidate
        if hits.count == 1 then return hits[1]
        if hits.count > 1 then return ""
        local legacy = root + "\\3d\\" + leaf
        if doesFileExist legacy then legacy else ""
    ),

    fn nonDDSProductionTextureRefs =
    (
        /*
            MAX 材质按规则保留 TGA。C3 导出不再要求先把材质重链为 DDS；
            DDS 由独立转换按钮写入资源根\C3，不能反向修改材质球。
        */
        #()
    ),
    fn referencedDDSSourcePaths =
    (
        local out = #()
        local errors = #()
        rejectedPSDSourcePaths = #()
        lastError = ""
        for b in ddsConversionBitmapTextures() do
        (
            local source = asText b.filename
            local ext = toLower (getFilenameType source)
            if ext == ".psd" do append rejectedPSDSourcePaths source
            if ext == ".tga" then
            (
                local resolved = resolveTextureSource source
                if resolved == "" then append errors ("找不到或存在歧义：" + source)
                else if findItem out resolved == 0 do append out resolved
            )
            else if ext != ".dds" do append errors ("生产贴图必须为 TGA：" + source)
        )
        if errors.count > 0 do
        (
            lastError = "生产贴图尚未就绪，未开始转换：\n"
            for detail in makeUniqueArray errors do lastError += detail + "\n"
        )
        out
    ),

    fn directDDSReferenceCount =
    (
        local count = 0
        for b in bitmapTextures() do
        (
            local fileName = ""
            try(fileName = asText b.filename)catch(fileName = "")
            if toLower (getFilenameType fileName) == ".dds" do
                count += 1
        )
        count
    ),

    fn ddsFolderForSource source =
    (
        local root = ""
        try(root = currentMaxResourceRoot())catch(root = "")
        if root == "" do root = externalRoot
        if root != "" do
        (
            root = trimTrailingPathSeparators root
            try(makeDir (root + "\\C3"))catch()
            if doesDirectoryExist (root + "\\C3") do return (root + "\\C3")
        )
        trimTrailingPathSeparators (getFilenamePath (asText source))
    ),

    fn relinkProductionTexturesToDDS =
    (
        /*
            兼容旧版界面调用，但按新规则永远不修改 MAX 材质球中的 TGA。
        */
        0
    ),

    fn uniqueC3Path folder stem =
    (
        folder + "\\" + stem + ".c3"
    ),

    fn cleanupC3ExportDocs folder =
    (
        for path in (join (getFiles (folder + "\\C3Exp*.txt")) (getFiles (folder + "\\C3Exp*.log"))) where findItem exportLogBaseline path == 0 do
            try(deleteFile path)catch()
        true
    ),

    fn c3PathForExport folder stem usedPaths =
    (
        local path = folder + "\\" + stem + ".c3"
        if findItem (for item in usedPaths collect toLower item) (toLower path) > 0 do throw ("同批次 C3 重名：" + stem + "；请先区分物件贴图名称。")
        path
    ),

    fn restoreC3ExportTimeRange oldRange oldTime rangeAdjusted =
    (
        if rangeAdjusted do
        (
            try(animationRange = oldRange)catch()
            try(sliderTime = oldTime)catch()
        )
    ),

    fn copyC3TexturesForNode n folder = (#(#(), #())),

    fn makeRenderPreviewSet nodes center angleDeg =
    (
        local copies = #()
        local root = undefined
        root = Dummy name:"ConquerRenderTmp_Root" pos:center boxsize:[10,10,10]

        for n in nodes where isValidNode n do
        (
            local c = undefined
            local tm = undefined
            try(c = copy n)catch(c = undefined)
            if c != undefined do
            (
                append copies c
                try(c.name = "ConquerRenderTmp_" + (asText n.name))catch()
                try(tm = c.transform)catch()
                try(c.parent = root)catch()
                if tm != undefined do try(c.transform = tm)catch()
                try(unhide c)catch()
            )
        )

        try(root.rotation = eulerAngles 0 0 angleDeg)catch()
        #(root, copies)
    ),

    fn moveRenderPreviewSetToCenter root copies wantedCenter =
    (
        local bounds = getEvaluatedNodesWorldBounds copies
        if bounds != undefined and root != undefined do
        (
            local delta = wantedCenter - bounds[4]
            try(root.pos = root.pos + delta)catch()
        )
        true
    ),

    fn makeRenderOutputPath =
    (
        local root = outputResourceRoot()
        local folder = ""
        if root == "" then return ""
        folder = root + "\\渲染图"
        try(makeDir folder)catch()
        if not doesDirectoryExist folder then return ""
        folder + "\\" + currentMaxStem() + "_渲染图.jpg"
    ),

    fn makeInterfaceRenderOutputFolder =
    (
        local root = outputResourceRoot()
        local renderFolder = ""
        local interfaceFolder = ""
        if root == "" then return ""
        renderFolder = root + "\\渲染图"
        try(makeDir renderFolder)catch()
        if not doesDirectoryExist renderFolder then return ""
        interfaceFolder = renderFolder + "\\界面"
        try(makeDir interfaceFolder)catch()
        if not doesDirectoryExist interfaceFolder then return ""
        interfaceFolder
    ),

    fn cleanupRenderTemporaryNodes =
    (
        local tempNodes = #()
        local tempCameras = #()
        local tempTargets = #()
        try
        (
            for n in objects where isValidNode n do
            (
                local nodeName = ""
                try(nodeName = toLower (asText n.name))catch(nodeName = "")
                if (matchPattern nodeName pattern:"conquerinterfacetmp_*" ignoreCase:true) or (matchPattern nodeName pattern:"conquerrendertmp_*" ignoreCase:true) do
                (
                    append tempNodes n
                    if matchPattern nodeName pattern:"*camera*" ignoreCase:true do
                        append tempCameras n
                    if matchPattern nodeName pattern:"*target*" ignoreCase:true do
                        append tempTargets n
                )
            )
        )
        catch()

        for n in tempCameras where isValidNode n do
        (
            try(delete n)catch()
        )
        for n in tempTargets where isValidNode n do
        (
            try(delete n)catch()
        )
        for n in tempNodes where isValidNode n do
        (
            try(delete n)catch()
        )
        true
    ),

    fn renderPreviewImage =
    (
        lastError = ""
        local nodes = #()
        local originalHidden = #()
        local oldSelection = #()
        local tempNodes = #()
        local renderCopies = #()
        local renderSets = #()
        local sourceBounds = undefined
        local renderBounds = undefined
        local center = [0,0,0]
        local renderCenter = [0,0,0]
        local dims = [1,1,1]
        local renderDims = [1,1,1]
        local spacing = 100.0
        local outputPath = ""
        local cam = undefined
        local targetObj = undefined
        local oldRenderer = undefined
        local previewScanline = undefined
        local oldWidth = 0
        local oldHeight = 0
        local oldPixelAspect = 1.0
        local oldRenderType = undefined
        local oldViewType = undefined
        local oldViewCamera = undefined
        local oldViewTM = undefined
        local oldBackground = color 127 127 127
        local oldAmbient = color 0 0 0
        local oldTint = color 255 255 255
        local stage = "初始化"
        local ok = false
        local renderSucceeded = false
        try(cleanupRenderTemporaryNodes())catch()

        try
        (
            /*
                自动渲染必须以当前打开的 MAX 为准，不能沿用上一次
                操作留下的 externalRoot，否则可能输出到旧资源包。
            */
            local currentRoot = ""
            try(currentRoot = currentMaxResourceRoot())catch(currentRoot = "")
            if currentRoot != "" and doesDirectoryExist currentRoot do
                externalRoot = currentRoot

            stage = "确定渲染图路径"
            outputPath = makeRenderOutputPath()
            if outputPath == "" do
            (
                messageBox "无法确定渲染图目录。请先保存 MAX，或先选择资源目录。" title:"征服MAX模型检查器"
                return false
            )

            stage = "获取生产模型"
            nodes = getGeometryNodes()
            if nodes.count == 0 do
            (
                messageBox "场景中没有可渲染的生产几何对象。" title:"征服MAX模型检查器"
                return false
            )

            stage = "计算原模型包围盒"
            sourceBounds = getEvaluatedNodesWorldBounds nodes
            if sourceBounds == undefined do
            (
                messageBox "无法计算模型包围盒，暂不能自动渲染。" title:"征服MAX模型检查器"
                return false
            )

            center = sourceBounds[4]
            dims = sourceBounds[3]
            spacing = (amax dims.x dims.y) * 1.20
            if spacing < 0.001 do spacing = dims.z * 0.35
            if spacing < 10.0 do spacing = 10.0

            stage = "保存场景状态"
            try(oldSelection = selection as array)catch(oldSelection = #())
            try(oldRenderer = renderers.production)catch(oldRenderer = undefined)
            try(oldWidth = renderWidth)catch()
            try(oldHeight = renderHeight)catch()
            try(oldPixelAspect = renderPixelAspect)catch()
            try(oldRenderType = getRenderType())catch()
            try(oldViewType = viewport.getType())catch()
            try(oldViewCamera = viewport.getCamera())catch()
            try(oldViewTM = viewport.getTM())catch()
            try(oldBackground = backgroundColor)catch()
            try(oldAmbient = ambientColor)catch()
            try(oldTint = lightTintColor)catch()
            for n in nodes where isValidNode n do
            (
                local wasHidden = false
                try(wasHidden = n.isHidden)catch(try(wasHidden = isHidden n)catch(wasHidden = false))
                append originalHidden #(n, wasHidden)
            )

            undo off
            (
                stage = "创建临时三视图模型"
                local angles = #(0.0, 30.0, 150.0)
                local offsets = #(-1.0, 0.0, 1.0)
                for i = 1 to 3 do
                (
                    local setData = makeRenderPreviewSet nodes center angles[i]
                    append renderSets setData
                    append tempNodes setData[1]
                    join tempNodes setData[2]
                    join renderCopies setData[2]
                )

            for i = 1 to 3 do
            (
                moveRenderPreviewSetToCenter renderSets[i][1] renderSets[i][2] (center + [spacing * offsets[i], 0, 0])
            )

                stage = "隐藏原模型"
                for item in originalHidden where isValidNode item[1] do try(hide item[1])catch()
                try(clearSelection())catch()

                stage = "计算渲染构图"
                renderBounds = getEvaluatedNodesWorldBounds renderCopies
                renderCenter = center
                if renderBounds != undefined do
                (
                    renderCenter = renderBounds[4]
                    renderDims = renderBounds[3]
                )

                /*
                    相机按三组临时复制体的实际世界包围盒取景。
                    正交相机的显示范围同时受目标距离和视野角影响。
                */
                stage = "创建正交相机"
                targetObj = TargetObject name:"ConquerRenderTmp_Target" pos:renderCenter
                append tempNodes targetObj
                local pitch = 15.0
                local projectedHeight = (renderDims.z * (cos pitch)) + (renderDims.y * (sin pitch))
                /*
                    Fit both projected dimensions to the 512:256 frame.
                    The larger required distance is the limiting dimension.
                */
                local horizontalFov = 65.47
                local verticalFov = 2.0 * (atan ((tan (horizontalFov / 2.0)) / 2.0))
                local frameMargin = 1.12
                local widthDistance = (renderDims.x * frameMargin) / (2.0 * (tan (horizontalFov / 2.0)))
                local heightDistance = (projectedHeight * frameMargin) / (2.0 * (tan (verticalFov / 2.0)))
                local distance = amax widthDistance heightDistance
                if distance < 100.0 do distance = 100.0
                cam = Targetcamera name:"ConquerRenderTmp_Camera" pos:(renderCenter + [0, -distance * (cos pitch), distance * (sin pitch)]) target:targetObj
                append tempNodes cam
                try(cam.orthoProjection = true)catch()
                try(cam.fov = horizontalFov)catch()
                try(cam.farrange = distance * 4.0)catch()
                /*
                    Keep the active viewport and renderer on the temporary
                    camera while the render is prepared. This prevents a
                    stale perspective/region viewport from affecting the
                    camera framing or the render window.
                */
                try(viewport.setCamera cam)catch()
                try(setRenderType #view)catch()
                try(forceCompleteRedraw())catch()

                stage = "设置规范渲染环境"
                try(fixGammaSettings())catch()
                try(fixProductRenderMode())catch()
                try(renderers.production = Default_Scanline_Renderer())catch()
                try(previewScanline = renderers.production)catch()
                if previewScanline != undefined do
                (
                    try(previewScanline.mapping = true)catch()
                    try(previewScanline.shadows = true)catch()
                    try(previewScanline.autoReflect = true)catch()
                    try(previewScanline.forceWireframe = false)catch()
                    try(previewScanline.enableSSE = false)catch()
                    try(previewScanline.antialiasing = true)catch()
                    try(previewScanline.filterMaps = true)catch()
                    try(previewScanline.antiAliasFilter = Area())catch()
                    try(previewScanline.antiAliasFilterSize = 1.5)catch()
                    try(previewScanline.globalSamplerEnabled = false)catch()
                    try(previewScanline.enablePixelSampler = true)catch()
                    try(previewScanline.globalSamplerSampleMaps = true)catch()
                )
                try(renderWidth = 512)catch()
                try(renderHeight = 256)catch()
                try(renderPixelAspect = 1.0)catch()
                try(backgroundColor = color 127 127 127)catch()
                try(ambientColor = color 0 0 0)catch()
                try(lightTintColor = color 255 255 255)catch()
                local stagedRender = (getFilenamePath outputPath) + "ConquerRender_" + (newRunId()) + ".jpg"

                stage = "渲染输出"
                local bm = undefined
                try
                (
                    /*
                        vfb:true is intentional: the user should see the
                        exact camera render in 3ds Max while the same bitmap
                        is also written to the 渲染图 folder.
                    */
                    bm = render camera:cam outputWidth:512 outputHeight:256 pixelAspect:1.0 renderType:#normal outputFile:stagedRender vfb:true
                    if bm != undefined do close bm
                    commitOutput stagedRender outputPath
                    renderSucceeded = true
                )
                catch
                (
                    lastError = exceptionText "渲染命令失败"
                    if doesFileExist stagedRender do try(deleteFile stagedRender)catch()
                )
                if renderSucceeded do
                    ok = doesFileExist outputPath
            )
        )
        catch
        (
            if lastError == "" do
                lastError = "渲染图生成失败，阶段：" + stage + "；" + (exceptionText "未知错误")
            ok = false
        )

        try
        (
            undo off
            (
                for n in tempNodes where isValidNode n do try(delete n)catch()
                for item in originalHidden where isValidNode item[1] do
                (
                    if item[2] then
                        try(hide item[1])catch()
                    else
                        try(unhide item[1])catch()
                )
                try(clearSelection())catch()
                if oldSelection.count > 0 do
                (
                    local validSelection = for n in oldSelection where isValidNode n collect n
                    if validSelection.count > 0 do select validSelection
                )
            )
        )
        catch()

        try(if oldRenderer != undefined do renderers.production = oldRenderer)catch()
            if oldWidth > 0 do try(renderWidth = oldWidth)catch()
            if oldHeight > 0 do try(renderHeight = oldHeight)catch()
        try(renderPixelAspect = oldPixelAspect)catch()
        try(if oldRenderType != undefined do setRenderType oldRenderType)catch()
        try
        (
            if oldViewCamera != undefined then
                viewport.setCamera oldViewCamera
            else if oldViewType != undefined then
            (
                viewport.setType oldViewType
                if oldViewTM != undefined do viewport.setTM oldViewTM
            )
        )
        catch()
        try(forceCompleteRedraw())catch()
        try(backgroundColor = oldBackground)catch()
        try(ambientColor = oldAmbient)catch()
        try(lightTintColor = oldTint)catch()

        if ok then
        (
            if not silentSuccessMessages do
                messageBox ("渲染图已生成：\n" + outputPath) title:"征服MAX模型检查器"
            true
        )
        else
        (
            if lastError == "" do lastError = "渲染命令执行完成，但没有生成图片文件。"
            messageBox lastError title:"征服MAX模型检查器"
            false
        )
    ),

    fn renderInterfaceUI =
    (
        lastError = ""
        local nodes = #()
        local originalHidden = #()
        local oldSelection = #()
        local tempNodes = #()
        local outputFolder = ""
        local oldRenderer = undefined
        local previewScanline = undefined
        local oldWidth = 0
        local oldHeight = 0
        local oldPixelAspect = 1.0
        local oldRenderType = undefined
        local oldViewType = undefined
        local oldViewCamera = undefined
        local oldViewTM = undefined
        local oldBackground = color 127 127 127
        local oldAmbient = color 0 0 0
        local oldTint = color 255 255 255
        local oldUseEnvironmentMap = true
        local oldEnvironmentMap = undefined
        local oldIterative = false
        local stage = "初始化"
        local successCount = 0
        local skippedCount = 0
        local renderIndex = 0
        local failed = #()
        try(cleanupRenderTemporaryNodes())catch()

        try
        (
            /*
                界面 UI 图按生产模型逐个输出，使用当前 MAX 的资源目录。
                不使用上一次界面状态，避免输出到旧工程。
            */
            local currentRoot = ""
            try(currentRoot = currentMaxResourceRoot())catch(currentRoot = "")
            if currentRoot != "" and doesDirectoryExist currentRoot do
                externalRoot = currentRoot

            stage = "确定界面渲染目录"
            outputFolder = makeInterfaceRenderOutputFolder()
            if outputFolder == "" do
            (
                lastError = "无法确定界面渲染目录。请先保存 MAX，或先选择资源目录。"
                return false
            )

            stage = "获取生产模型"
            local allNodes = #()
            try(allNodes = getGeometryNodes())catch(allNodes = #())
            for n in allNodes where isValidNode n do
            (
                if interfaceNodeExcludedByTexture n then
                    skippedCount += 1
                else
                    append nodes n
            )
            if nodes.count == 0 do
            (
                if skippedCount > 0 then
                    lastError = "没有可渲染的生产几何对象；已跳过 " + (skippedCount as string) + " 个贴图名以 _F 结尾的物件。"
                else
                    lastError = "场景中没有可渲染的生产几何对象。"
                return false
            )

            stage = "保存场景状态"
            try(oldSelection = selection as array)catch(oldSelection = #())
            try(oldRenderer = renderers.production)catch(oldRenderer = undefined)
            try(oldWidth = renderWidth)catch()
            try(oldHeight = renderHeight)catch()
            try(oldPixelAspect = renderPixelAspect)catch()
            try(oldRenderType = getRenderType())catch()
            try(oldViewType = viewport.getType())catch()
            try(oldViewCamera = viewport.getCamera())catch()
            try(oldViewTM = viewport.getTM())catch()
            try(oldBackground = backgroundColor)catch()
            try(oldAmbient = ambientColor)catch()
            try(oldTint = lightTintColor)catch()
            try(oldUseEnvironmentMap = useEnvironmentMap)catch(oldUseEnvironmentMap = true)
            try(oldEnvironmentMap = environmentMap)catch(oldEnvironmentMap = undefined)
            try(oldIterative = maxOps.rendUseIterative)catch(oldIterative = false)

            try
            (
                for n in geometry where isValidNode n do
                (
                    local wasHidden = false
                    try(wasHidden = n.isHidden)catch(try(wasHidden = isHidden n)catch(wasHidden = false))
                    append originalHidden #(n, wasHidden)
                )
            )
            catch()

            undo off
            (
                stage = "设置界面渲染环境"
                try(fixGammaSettings())catch()
                try(fixProductRenderMode())catch()
                try(renderers.production = Default_Scanline_Renderer())catch()
                try(previewScanline = renderers.production)catch()
                if previewScanline != undefined do
                (
                    try(previewScanline.mapping = true)catch()
                    try(previewScanline.shadows = true)catch()
                    try(previewScanline.autoReflect = true)catch()
                    try(previewScanline.forceWireframe = false)catch()
                    try(previewScanline.enableSSE = false)catch()
                    try(previewScanline.antialiasing = true)catch()
                    try(previewScanline.filterMaps = true)catch()
                    try(previewScanline.antiAliasFilter = Area())catch()
                    try(previewScanline.antiAliasFilterSize = 1.5)catch()
                    try(previewScanline.globalSamplerEnabled = false)catch()
                    try(previewScanline.enablePixelSampler = true)catch()
                    try(previewScanline.globalSamplerSampleMaps = true)catch()
                )
                try(setRenderType #view)catch()
                try(useEnvironmentMap = false)catch()
                try(environmentMap = undefined)catch()
                /*
                    PNG 输出使用无环境图的场景，背景色只作为 RGB 备用值；
                    PNG 的背景区域保持透明 Alpha，不使用纯色背景。
                */
                try(backgroundColor = color 0 0 0)catch()
                try(ambientColor = color 0 0 0)catch()
                try(lightTintColor = color 255 255 255)catch()

                for i = 1 to nodes.count do
                (
                    local sourceNode = nodes[i]
                    local renderRoot = undefined
                    local renderCopy = undefined
                    local copyTransform = undefined
                    local targetObj = undefined
                    local cam = undefined
                    local bounds = undefined
                    local sourceBounds = undefined
                    local sourceCenter = [0,0,0]
                    local center = [0,0,0]
                    local dims = [1,1,1]
                    local outputPath = ""
                    local nodeName = "物件" + (i as string)
                    local imageWidth = 800
                    local imageHeight = 600
                    local aspect = 1.333333
                    local pitch = 15.0
                    local horizontalFov = 65.47
                    local verticalFov = 51.8
                    local frameMargin = 1.05
                    local projectedHeight = 1.0
                    local widthDistance = 0.01
                    local heightDistance = 0.01
                    local distance = 0.01
                    local renderSucceeded = false
                    local renderError = ""

                    if isValidNode sourceNode then
                    (
                        renderIndex += 1
                        try(nodeName = asText sourceNode.name)catch()
                        stage = "准备界面物件 " + nodeName
                        try
                        (
                            /*
                                只隐藏几何对象，灯光和渲染设置仍沿用正式产品渲染环境。
                                复制体挂到临时根节点后旋转 30 度，原对象不做变换。
                            */
                            for item in originalHidden where isValidNode item[1] do
                                try(hide item[1])catch()

                            sourceBounds = getEvaluatedNodesWorldBounds #(sourceNode)
                            if sourceBounds == undefined then
                                renderError = "无法计算对象原始包围盒：" + nodeName
                            else
                            (
                                sourceCenter = sourceBounds[4]
                                renderRoot = Dummy name:"ConquerInterfaceTmp_Root" pos:sourceCenter boxsize:[10,10,10]
                                append tempNodes renderRoot
                                try(renderCopy = copy sourceNode)catch(renderCopy = undefined)
                                if renderCopy == undefined then
                                    renderError = "复制对象失败：" + nodeName
                                else
                                (
                                    append tempNodes renderCopy
                                    try(renderCopy.name = "ConquerInterfaceTmp_" + nodeName)catch()
                                    try(copyTransform = renderCopy.transform)catch(copyTransform = undefined)
                                    try(renderCopy.parent = renderRoot)catch()
                                    if copyTransform != undefined do try(renderCopy.transform = copyTransform)catch()
                                    try(unhide renderCopy)catch()
                                    try(renderCopy.isHidden = false)catch()
                                    try(renderRoot.rotation = eulerAngles 0 0 30.0)catch()
                                    try(forceCompleteRedraw())catch()

                                    bounds = getEvaluatedNodesWorldBounds #(renderCopy)
                                    if bounds == undefined then
                                        renderError = "无法计算对象包围盒：" + nodeName
                                    else
                                    (
                                        center = bounds[4]
                                        dims = bounds[3]
                                        if dims.x < 0.001 do dims.x = 0.001
                                        if dims.y < 0.001 do dims.y = 0.001
                                        if dims.z < 0.001 do dims.z = 0.001

                                        /*
                                            Choose the canvas direction from the
                                            camera-space height, not raw Z. This
                                            keeps rotated small objects tightly framed.
                                        */
                                        projectedHeight = (dims.z * (cos pitch)) + (dims.y * (sin pitch))
                                        if projectedHeight > dims.x then
                                        (
                                            imageWidth = 600
                                            imageHeight = 800
                                        )
                                        else
                                        (
                                            imageWidth = 800
                                            imageHeight = 600
                                        )
                                        aspect = imageWidth as float / imageHeight as float
                                        verticalFov = 2.0 * (atan ((tan (horizontalFov / 2.0)) / aspect))
                                        widthDistance = (dims.x * frameMargin) / (2.0 * (tan (horizontalFov / 2.0)))
                                        heightDistance = (projectedHeight * frameMargin) / (2.0 * (tan (verticalFov / 2.0)))
                                        distance = amax widthDistance heightDistance
                                        if distance < 0.01 do distance = 0.01

                                        targetObj = TargetObject name:"ConquerInterfaceTmp_Target" pos:center
                                        append tempNodes targetObj
                                        cam = Targetcamera name:"ConquerInterfaceTmp_Camera" pos:(center + [0, -distance * (cos pitch), distance * (sin pitch)]) target:targetObj
                                        append tempNodes cam
                                        try(cam.orthoProjection = true)catch()
                                        try(cam.fov = horizontalFov)catch()
                                        try(cam.farrange = distance * 4.0)catch()
                                        try(viewport.setCamera cam)catch()
                                        try(forceCompleteRedraw())catch()

                                        outputPath = outputFolder + "\\" + (renderIndex as string) + ".png"
                                        local stagedRender = outputFolder + "\\ConquerRender_" + (newRunId()) + ".png"
                                        stage = "渲染界面物件 " + (renderIndex as string)
                                        try
                                        (
                                            local bm = render camera:cam outputWidth:imageWidth outputHeight:imageHeight pixelAspect:1.0 renderType:#normal outputFile:stagedRender vfb:false
                                            if bm != undefined do close bm
                                            commitOutput stagedRender outputPath
                                            renderSucceeded = true
                                        )
                                        catch
                                        (
                                            renderError = exceptionText "渲染命令失败"
                                            if doesFileExist stagedRender do try(deleteFile stagedRender)catch()
                                        )
                                    )
                                )
                            )
                            if renderSucceeded and doesFileExist outputPath then
                                successCount += 1
                            else
                            (
                                if renderError == "" do renderError = "渲染完成但没有生成 PNG 文件。"
                                append failed #((renderIndex as string), nodeName, renderError)
                            )
                        )
                        catch
                        (
                            if renderError == "" do renderError = exceptionText "界面物件渲染失败"
                            append failed #((renderIndex as string), nodeName, renderError)
                        )
                    )
                    else
                        append failed #((renderIndex as string), nodeName, "对象已失效。")

                    for temp in tempNodes where isValidNode temp do
                    (
                        try(delete temp)catch()
                    )
                    tempNodes = #()
                )
            )
        )
        catch
        (
            if lastError == "" do
                lastError = "界面 UI 渲染失败，阶段：" + stage + "；" + (exceptionText "未知错误")
        )

        try
        (
            undo off
            (
                for temp in tempNodes where isValidNode temp do
                (
                    try(delete temp)catch()
                )
                for item in originalHidden where isValidNode item[1] do
                (
                    if item[2] then
                        try(hide item[1])catch()
                    else
                        try(unhide item[1])catch()
                )
                try(clearSelection())catch()
                if oldSelection.count > 0 do
                (
                    local validSelection = for n in oldSelection where isValidNode n collect n
                    if validSelection.count > 0 do select validSelection
                )
            )
        )
        catch()
        try(cleanupRenderTemporaryNodes())catch()

        try(if oldRenderer != undefined do renderers.production = oldRenderer)catch()
        if oldWidth > 0 do try(renderWidth = oldWidth)catch()
        if oldHeight > 0 do try(renderHeight = oldHeight)catch()
        try(renderPixelAspect = oldPixelAspect)catch()
        try(if oldRenderType != undefined do setRenderType oldRenderType)catch()
        try
        (
            if oldViewCamera != undefined then
                viewport.setCamera oldViewCamera
            else if oldViewType != undefined then
            (
                viewport.setType oldViewType
                if oldViewTM != undefined do viewport.setTM oldViewTM
            )
        )
        catch()
        try(forceCompleteRedraw())catch()
        try(backgroundColor = oldBackground)catch()
        try(ambientColor = oldAmbient)catch()
        try(lightTintColor = oldTint)catch()
        try(environmentMap = oldEnvironmentMap)catch()
        try(useEnvironmentMap = oldUseEnvironmentMap)catch()
        try(maxOps.rendUseIterative = oldIterative)catch()

        if successCount == 0 and skippedCount > 0 and failed.count == 0 do
        (
            lastError = "全部物件因 _F 贴图规则跳过，本次没有新增 UI 图片。"
            return true
        )
        if successCount > 0 then
        (
            if failed.count > 0 do
            (
                lastError = "界面 UI 渲染完成 " + (successCount as string) + " 个，跳过 " + (skippedCount as string) + " 个，失败 " + (failed.count as string) + " 个。\n"
                for item in failed do
                    lastError += item[1] + "（" + item[2] + "）：" + item[3] + "\n"
            )
            if not silentSuccessMessages and failed.count == 0 do
                messageBox ("界面 UI 渲染完成，共 " + (successCount as string) + " 个 PNG；跳过 " + (skippedCount as string) + " 个 _F 贴图物件。\n输出目录：\n" + outputFolder) title:"征服MAX模型检查器"
            true
        )
        else
        (
            if lastError == "" do
                lastError = "界面 UI 渲染未生成 PNG 文件。"
            messageBox lastError title:"征服MAX模型检查器"
            false
        )
    ),

    fn exportC3Objects =
    (
        lastError = ""
        local root = ""
        local folder = ""
        local nodes = #()
        local oldSelection = #()
        local exported = #()
        local failed = #()
        local textureCopied = #()
        local textureCopyFailed = #()
        local usedTargets = #()
        local stem = ""
        local target = ""
        local stage = "初始化"
        local wasIsolated = false
        local oldAnimationRange = undefined
        local oldSliderTime = undefined
        local exportRangeAdjusted = false
        local blockedTextures = #()
        local tempTarget = ""

        try
        (
            stage = "确定资源根目录"
            root = c3ResourceRoot()
            if root == "" do
            (
                messageBox "无法确定资源根目录。请先保存 MAX，或先选择资源目录。" title:"征服MAX模型检查器"
                return false
            )

            stage = "创建 C3 导出目录"
            folder = root + "\\C3"
            try(makeDir folder)catch()
            if not doesDirectoryExist folder do
            (
                messageBox ("无法创建 C3 导出目录：\n" + folder) title:"征服MAX模型检查器"
                return false
            )

            stage = "获取生产几何对象"
            nodes = getGeometryNodes()
            if nodes.count == 0 do
            (
                messageBox "场景中没有可导出的生产几何对象。" title:"征服MAX模型检查器"
                return false
            )

            exportLogBaseline = join (getFiles (folder + "\\C3Exp*.txt")) (getFiles (folder + "\\C3Exp*.log"))
            local names = #()
            for node in nodes do
            (
                if not materialIsPlainStandard node.material do throw (node.name + " 尚未成为独立 Standard 材质物件。")
                if classOf node.baseObject == Editable_Poly do
                (
                    if not (polyOp.getMapSupport node 1) or (polyOp.getNumMapVerts node 1) == 0 do throw (node.name + " 缺少 UV 通道1，C3导出前请先建立贴图坐标。")
                )
                local name = textureStemForNode node
                if name == "" do throw (node.name + " 缺少颜色贴图名称。")
                local targetName = toLower (safeC3Stem name)
                if findItem names targetName > 0 do throw ("多个物件使用同名贴图：" + name + "；请先区分，避免同批次覆盖。")
                append names targetName
            )
            stage = "检查 C3 贴图格式"
            referencedDDSSourcePaths()
            if lastError != "" do throw lastError
            if rejectedPSDSourcePaths.count > 0 do
            (
                lastError = "PSD贴图不能进入 C3，也不能转换DDS格式，只允许TGA转换。请先将 MAX 材质中的 PSD 替换为 TGA。"
                messageBox lastError title:"征服MAX模型检查器"
                return false
            )
        )
        catch
        (
            lastError = "C3 导出执行失败，阶段：" + stage + "\n" + (exceptionText "未知错误")
            if not silentSuccessMessages do messageBox lastError title:"征服MAX模型检查器"
            return false
        )

        try
        (
            stage = "保存当前选择集"
            try(oldSelection = selection as array)catch(oldSelection = #())
            stage = "设置 C3 静态导出时间范围"
            try
            (
                oldAnimationRange = animationRange
                oldSliderTime = sliderTime
                animationRange = interval oldSliderTime oldSliderTime
                exportRangeAdjusted = true
            )
            catch(exportRangeAdjusted = false)
            clearSelection()
            for n in nodes where isValidNode n do
            (
                stage = "准备对象 " + (try(asText n.name)catch("object"))
                try
                (
                    stage = "读取贴图名称：" + (try(asText n.name)catch("object"))
                    stem = safeC3Stem (textureStemForNode n)
                    stage = "创建导出文件名：" + (try(asText n.name)catch("object"))
                    target = c3PathForExport folder stem usedTargets
                    append usedTargets target
                    /* 同批次重名已拦截；新导出通过后再替换已有目标。 */
                    stage = "选中对象：" + (try(asText n.name)catch("object"))
                    clearSelection()
                    select n
                    if IsolateSelection.IsolateSelectionModeActive() do
                    (
                        stage = "退出已有孤立模式"
                        IsolateSelection.ExitIsolateSelectionMode()
                    )
                    stage = "孤立对象：" + (asText n.name)
                    IsolateSelection.EnterIsolateSelectionMode()
                    wasIsolated = true
                    if wasIsolated do
                    (
                    stage = "普通导出 C3：" + (asText n.name)
                        /*
                            C3 插件只在普通 Export 流程中按 .c3 后缀被解析。
                            不传 selectedOnly，也不传 using；隔离状态保证场景中
                            只有当前物件对插件可见。
                        */
                        tempTarget = folder + "\\ConquerExport_" + (newRunId()) + ".c3"
                        local oldWorkingDir = (dotNetClass "System.IO.Directory").GetCurrentDirectory()
                        try
                        (
                            (dotNetClass "System.IO.Directory").SetCurrentDirectory folder
                            exportFile tempTarget #noPrompt
                        )
                        catch
                        (
                            (dotNetClass "System.IO.Directory").SetCurrentDirectory oldWorkingDir
                            throw()
                        )
                        (dotNetClass "System.IO.Directory").SetCurrentDirectory oldWorkingDir
                        if not doesFileExist tempTarget do throw "导出器未生成新 C3。"
                        if getFileSize tempTarget <= 0 do throw "导出器生成了空 C3。"
                        try
                        (
                            commitOutput tempTarget target
                        )catch(try(deleteFile tempTarget)catch(); throw (exceptionText "替换 C3 失败"))
                        stage = "退出孤立模式：" + (asText n.name)
                        IsolateSelection.ExitIsolateSelectionMode()
                        wasIsolated = false
                        cleanupC3ExportDocs folder
                        if doesFileExist target do
                        (
                            append exported #(n.name, target)
                            local textureResult = copyC3TexturesForNode n folder
                            join textureCopied textureResult[1]
                            if textureResult[2].count > 0 do
                                append textureCopyFailed #(n.name, textureResult[2])
                        )
                        if not doesFileExist target do
                        (
                            append failed #(n.name, "普通导出未生成 .c3 文件，可能未安装或未注册 C3 导出插件")
                        )
                    )
                )
                catch
                (
                    if wasIsolated do
                    (
                        try(IsolateSelection.ExitIsolateSelectionMode())catch()
                        wasIsolated = false
                    )
                    if tempTarget != "" and doesFileExist tempTarget do try(deleteFile tempTarget)catch()
                    cleanupC3ExportDocs folder
                    append failed #(n.name, "阶段=" + stage + "；" + (exceptionText "导出失败"))
                )
            )
        )
        catch
        (
            restoreC3ExportTimeRange oldAnimationRange oldSliderTime exportRangeAdjusted
            lastError = "C3 导出执行失败，阶段：" + stage + "\n" + (exceptionText "未知错误")
            if not silentSuccessMessages do messageBox lastError title:"征服MAX模型检查器"
            return false
        )
        restoreC3ExportTimeRange oldAnimationRange oldSliderTime exportRangeAdjusted
        /* C3 插件可能在 exportFile 返回后延迟写入日志，连续扫描清理。 */
        for cleanupPass = 1 to 1 do
        (

            cleanupC3ExportDocs folder
        )
        try
        (
            clearSelection()
            if oldSelection.count > 0 do select oldSelection
        )
        catch()

        if failed.count == 0 then
        (
            true
        )
        else
        (
            local detail = "C3 已导出 " + (exported.count as string) + " 个，失败 " + (failed.count as string) + " 个。\n目录：\n" + folder + "\n\n"
            for item in failed do detail += item[1] + "：" + item[2] + "\n"
            if textureCopyFailed.count > 0 do
            (
                detail += "\n贴图复制失败：\n"
                for item in textureCopyFailed do
                (
                    for textureItem in item[2] do
                        detail += textureItem[1] + "：" + textureItem[2] + "\n"
                )
            )
            if exported.count == 0 do
                detail = "未能通过普通 Export 流程生成 C3 文件。请确认 C3 插件已安装，并且在“文件 > 导出”中能看到 C3 格式。\n\n" + detail
            lastError = detail
            if not silentSuccessMessages do messageBox detail title:"征服MAX模型检查器"
            false
        )
    ),

    fn externalPassText =
    (
        local result = ""
        try(result = compactExternalDisplay "通过")catch(lastError = "外部通过结果读取失败。")
        result
    ),

    fn externalIssueText =
    (
        local result = ""
        try
        (
            result = compactExternalDisplay "不通过"
            result += compactExternalDisplay "待确认"
            result += compactExternalDisplay "报错"
        )
        catch(lastError = "外部问题结果读取失败。")
        result
    )

)

ConquerMaxChecker = ConquerMaxCheckerStruct()
try(ConquerMaxChecker.refreshImportedBaseState())catch()

try(destroyDialog conquerOneClickProgressRollout)catch()
rollout conquerOneClickProgressRollout "一键出图进度" width:420 height:145
(
    label lblProgressStage "准备一键出图..." pos:[20,18] width:380 height:22
    progressBar pbProgress pos:[20,48] width:380 height:16 range:100 value:0
    label lblProgressPercent "0%" pos:[20,78] width:380 height:22

    button btnCancel "当前阶段结束后停止" pos:[200,104] width:200 height:26
    on btnCancel pressed do
    (
        ConquerMaxChecker.cancelRequested = true
        lblProgressStage.text = "已请求停止；正在完成当前步骤..."
        btnCancel.enabled = false
    )
    fn updateProgress stageText pct =
    (
        local progressValue = pct
        if progressValue < 0 do progressValue = 0
        if progressValue > 100 do progressValue = 100
        if stageText == "" do stageText = "一键出图处理中..."
        lblProgressStage.text = stageText
        pbProgress.value = progressValue
        lblProgressPercent.text = (progressValue as string) + "%"
        try(windows.processPostedMessages())catch()
        true
    )
)

rollout conquerCheckerRollout "征服MAX · 检查 / 整理 / 输出 v0.2.9" width:840 height:784
(
    local externalStatusText = "就绪"
    local displayModeText = "检查只读；修改前自动备份"
    groupBox gbBase "观察与处理范围" pos:[10,8] width:820 height:82
    editText edtBase "基础体:" pos:[24,30] width:530 height:20 readOnly:true
    button btnPickBase "导入基础体" pos:[570,28] width:115 height:26
    button btnRemoveBase "移除基础体" pos:[695,28] width:115 height:26
    label lblBaseDims "基础体：未导入" pos:[24,62] width:540 height:18
    checkbox chkSelected "仅处理选中模型" pos:[640,62] width:165 checked:false tooltip:"限制模型、材质、转换与导出；环境清理仍作用于场景。"
    groupBox gbMaxTools "1 检查与修复 · 模型修改会整体归零、重置法线并塌陷，自动备份原场景" pos:[10,100] width:820 height:108
    button btnFullCheck "检查全部" pos:[24,126] width:140 height:30
    button btnEnvCheck "环境检查" pos:[184,126] width:130 height:30
    button btnModelCheck "模型检查" pos:[334,126] width:130 height:30
    button btnMaterialCheck "材质 / 贴图检查" pos:[484,126] width:150 height:30
    button btnOpenBackup "打开备份文件夹" pos:[654,126] width:155 height:30 tooltip:"打开 %LOCALAPPDATA%\\ConquerMaxChecker\\backups；不自动载入或替换当前场景。"
    button btnFullFix "全部修复" pos:[24,166] width:140 height:30
    button btnEnvFix "修复环境 / 清理" pos:[184,166] width:130 height:30
    button btnModelFix "修复模型 / 归零" pos:[334,166] width:130 height:30
    button btnMaterialFix "修复材质并保存" pos:[484,166] width:150 height:30
    button btnLocate "选中问题模型" pos:[654,166] width:155 height:30
    groupBox gbExternal "2 当前资源包" pos:[10,218] width:820 height:91
    editText edtExternalRoot "目录:" pos:[24,242] width:490 height:20 readOnly:true
    button btnPickExternal "选目录检查" pos:[526,239] width:85 height:26
    button btnPickFromMax "从 MAX 拾取" pos:[620,239] width:100 height:26
    button btnOpenMaxParent "打开目录" pos:[729,239] width:82 height:26
    button btnExternalCheck "检查文件夹" pos:[24,274] width:140 height:26
    button btnFixExternalHierarchy "整理文件并保存" pos:[184,274] width:180 height:26
    button btnOneClick "一键整理并出图" pos:[384,274] width:427 height:26
    groupBox gbOutput "3 输出 · 保留原贴图与 MAX 材质引用" pos:[10,319] width:820 height:100
    button btnConvertDDS "贴图 → DDS" pos:[24,344] width:140 height:28
    checkbox chkPSRefine "PS 精修 MIP0 / MIP1" pos:[184,347] width:260 checked:true
    dropdownlist ddlPSVersion "PS版本" pos:[490,343] width:300 items:#("自动（最新已注册版本）","Photoshop 2025","Photoshop 2022","Photoshop CS3","Photoshop CC 2019","Photoshop 2026") selection:1
    button btnConvertPNG "贴图 → PNG" pos:[24,377] width:140 height:28
    button btnExportC3 "导出 C3 物件" pos:[224,377] width:140 height:28
    button btnRenderPreview "场景预览 JPG" pos:[424,377] width:140 height:28
    button btnRenderInterface "物件 UI PNG" pos:[624,377] width:145 height:28
    button btnShowMax "MAX 结果" pos:[10,429] width:90 height:26
    button btnShowExternal "文件结果" pos:[110,429] width:90 height:26
    button btnShowMerged "合并结果" pos:[210,429] width:90 height:26
    button btnClear "清空结果" pos:[730,429] width:100 height:26
    label lblPass "通过项目" pos:[10,464] width:250 height:18
    label lblIssue "待处理 / 执行错误 / 输出详情" pos:[280,464] width:540 height:18
    editText edtPass "" pos:[10,486] width:250 height:235 readOnly:true
    editText edtIssue "" pos:[280,486] width:550 height:235 readOnly:true
    label lblStatus "就绪" pos:[10,733] width:820 height:42
    -- MAX 2015 requires rollout functions to be defined before their event handlers.
    fn psSettingsFile =
    (
        local folder = (dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA" + "\\ConquerMaxChecker"
        (dotNetClass "System.IO.Directory").CreateDirectory folder
        folder + "\\photoshop.ini"
    )
    fn selectPSVersion choiceIndex =
    (
        local versions = #("auto","2025","2022","CS3","2019","2026")
        if choiceIndex >= 1 and choiceIndex <= versions.count do
        (
            ConquerMaxChecker.psVersion = versions[choiceIndex]
            try(setINISetting (psSettingsFile()) "DDS" "version" (choiceIndex as string))catch()
        )
    )
    fn setBusy state =
    (
        ConquerMaxChecker.busy = state
        for control in #(btnFullCheck,btnEnvCheck,btnModelCheck,btnMaterialCheck,btnFullFix,btnEnvFix,btnModelFix,btnMaterialFix,btnExternalCheck,btnFixExternalHierarchy,btnOneClick,btnConvertDDS,btnConvertPNG,btnExportC3,btnRenderPreview,btnRenderInterface,btnPickBase,btnRemoveBase,btnPickExternal,btnPickFromMax,btnClear,btnLocate,btnOpenBackup,chkSelected,chkPSRefine,ddlPSVersion) do control.enabled = not state
    )

    on chkSelected changed state do ConquerMaxChecker.selectedOnly = state
    on btnOpenBackup pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local folder = ((dotNetClass "System.Environment").GetEnvironmentVariable "LOCALAPPDATA") + "\\ConquerMaxChecker\\backups"
        if not doesDirectoryExist folder do makeDir folder
        shellLaunch folder ""
        lblStatus.text = "备份位置：" + folder + "\r\n打开 .max 备份可恢复；此按钮只打开文件夹。"
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )
    on btnLocate pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local nodes = #()
        for item in ConquerMaxChecker.report where item.status != "通过" do
            for n in geometry where n.name == item.target and ConquerMaxChecker.isProductionNode n do append nodes n
        if nodes.count > 0 then select (makeUniqueArray nodes) else messageBox "当前结果没有可定位的模型；路径和材质问题请查看详情。"
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    fn refreshStatusText =
    (
        lblStatus.text = externalStatusText + "\r\n" + displayModeText
    )

    fn updateOneClickProgress pct stageText:"" =
    (
        local progressValue = pct
        if progressValue < 0 do progressValue = 0
        if progressValue > 100 do progressValue = 100
        try(conquerOneClickProgressRollout.updateProgress stageText progressValue)catch()
        try(windows.processPostedMessages())catch()
        if ConquerMaxChecker.cancelRequested do throw "已取消后续步骤；已生成的结果保留。"
        true
    )

    on conquerCheckerRollout open do
    (
        try
        (
            local settings = psSettingsFile()
            local enabled = getINISetting settings "DDS" "enabled"
            if enabled != "" do ConquerMaxChecker.psRefine = (enabled == "true")
            chkPSRefine.checked = ConquerMaxChecker.psRefine
            local choiceIndex = (getINISetting settings "DDS" "version") as integer
            if choiceIndex >= 1 and choiceIndex <= ddlPSVersion.items.count do
            (
                ddlPSVersion.selection = choiceIndex
                selectPSVersion choiceIndex
            )
        )catch()

        try
        (
            ConquerMaxChecker.refreshImportedBaseState()
            lblBaseDims.text = ConquerMaxChecker.baseStatusText()
        )
        catch()
    )

    on btnPickBase pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        try
        (
            local f = getOpenFileName caption:"选择基础体MAX文件" types:"3ds Max (*.max)|*.max|All Files (*.*)|*.*|"
            if f != undefined do
            (
                edtBase.text = f
                if ConquerMaxChecker.importBaseBody f then
                    lblBaseDims.text = ConquerMaxChecker.baseStatusText()
                else
                (
                    lblBaseDims.text = ConquerMaxChecker.importStatusText()
                    messageBox ("基础体文件读取失败。\n" + ConquerMaxChecker.lastError) title:"征服MAX模型检查器"
                )
            )
        )
        catch
        (
            try
            (
                ConquerMaxChecker.lastError = "导入按钮执行异常：" + (ConquerMaxChecker.exceptionText "未知错误")
            )
            catch
            (
                ConquerMaxChecker.lastError = "导入按钮执行异常，基础体未加入当前场景。"
            )
            lblBaseDims.text = ConquerMaxChecker.importStatusText()
            messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnEnvCheck pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.runEnvironmentCheck()
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        displayModeText = "当前显示：环境检查"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnEnvFix pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.resetReport()
        local fixOk = ConquerMaxChecker.fixEnvironmentOnly()
        ConquerMaxChecker.runEnvironmentCheck()
        if fixOk then
        (
            displayModeText = "当前显示：环境修改后检查"
        )
        else
            displayModeText = "当前显示：环境修改失败"
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnModelCheck pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.runModelCheck()
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        displayModeText = "当前显示：模型检查"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnModelFix pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.resetReport()
        local fixOk = ConquerMaxChecker.fixModelOnly()
        ConquerMaxChecker.runModelCheck()
        if fixOk then
        (
            displayModeText = "当前显示：模型修改后检查"
        )
        else
            displayModeText = "当前显示：模型修改失败"
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnMaterialCheck pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.runMaterialCheck()
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        displayModeText = "当前显示：贴图材质检查 / 路径检查"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnMaterialFix pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.resetReport()
        local fixOk = ConquerMaxChecker.fixMaterialOnly()
        ConquerMaxChecker.runMaterialCheck()
        if fixOk then
        (
            displayModeText = "当前显示：贴图材质修改后检查"
        )
        else
            displayModeText = "当前显示：贴图材质修改失败 / 路径去除失败"
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )


    on btnFullCheck pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.runAll()
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        displayModeText = "当前显示：MAX 内全检查"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnPickExternal pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local folder = getSavePath caption:"选择资源根目录"
        if folder != undefined do
        (
            ConquerMaxChecker.externalRoot = folder
            ConquerMaxChecker.externalRootManual = true
            edtExternalRoot.text = folder
            externalStatusText = ConquerMaxChecker.validateExternalRoot()
            refreshStatusText()
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnPickFromMax pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local maxFile = ""
        local root = ""
        try(maxFile = ConquerMaxChecker.currentMaxFullPath())catch(maxFile = "")
        if maxFile == undefined or maxFile == "" or not doesFileExist maxFile do
            maxFile = getOpenFileName caption:"选择生产MAX文件，自动拾取资源边界" types:"3ds Max (*.max)|*.max|All Files (*.*)|*.*|"
        if maxFile != undefined and maxFile != "" do
        (
            root = ConquerMaxChecker.resourceRootFromMaxFile maxFile
            if root == "" then
            (
                messageBox "无法根据这个 MAX 文件找到主文件夹。请确认该文件位于需要改名为 MAX 的同级文件夹内。" title:"征服MAX模型检查器"
            )
            else
            (
                ConquerMaxChecker.externalRoot = root
                ConquerMaxChecker.externalRootManual = (root != ConquerMaxChecker.currentMaxResourceRoot())
                edtExternalRoot.text = root
                externalStatusText = "已从 MAX 自动拾取当前资源边界；" + ConquerMaxChecker.validateExternalRoot()
                refreshStatusText()
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnExternalCheck pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        try
        (
            externalStatusText = "外部状态：执行中，请稍候..."
            refreshStatusText()
            try(windows.processPostedMessages())catch()

            if not ConquerMaxChecker.externalRootManual do try(ConquerMaxChecker.syncExternalRootToCurrentMax())catch()
            edtExternalRoot.text = ConquerMaxChecker.externalRoot

            if ConquerMaxChecker.externalRoot == "" then
            (
                externalStatusText = "外部状态：未选择资源目录"
                refreshStatusText()
                messageBox "请先点击“从MAX拾取”或“选择目录”。" title:"征服MAX模型检查器"
            )
            else if matchPattern (ConquerMaxChecker.validateExternalRoot()) pattern:"*不通过*" then
            (
                externalStatusText = ConquerMaxChecker.validateExternalRoot()
                refreshStatusText()
                messageBox "当前目录不像资源包目录，也没有找到包含 MAX 文件的目录。请重新选择资源包目录或 MAX 文件目录。" title:"征服MAX模型检查器"
            )
            else if ConquerMaxChecker.runExternalCheck() then
            (
                edtPass.text = ConquerMaxChecker.externalPassText()
                edtIssue.text = ConquerMaxChecker.externalIssueText()
                if edtPass.text == "" and edtIssue.text == "" do
                (
                    edtIssue.text = "外部 | 报错 | 报告 | 已生成报告，但 Max 未能读取报告内容。 | 请查看外部检查报告目录中的 TXT 文件。"
                )
                displayModeText = "当前显示：外部文件检查"
                externalStatusText = ConquerMaxChecker.validateExternalRoot() + "；报告已生成"
                refreshStatusText()
            )
            else
            (
                externalStatusText = "外部状态：执行失败"
                refreshStatusText()
                messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
            )
        )
        catch
        (
            ConquerMaxChecker.lastError = "外部检查按钮异常：" + (ConquerMaxChecker.exceptionText "未知错误")
            externalStatusText = "外部状态：报错"
            refreshStatusText()
            messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnFixExternalHierarchy pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local go = false
        local placementError = ""
        try(placementError = ConquerMaxChecker.currentMaxPlacementError())catch(placementError = "")
        if placementError != "" do
        (
            externalStatusText = "外部状态：MAX 文件位置不符合整理要求"
            refreshStatusText()
            messageBox placementError title:"征服MAX模型检查器"
            return()
        )
        ConquerMaxChecker.externalRootManual = false
        try(ConquerMaxChecker.syncExternalRootToCurrentMax())catch()
        edtExternalRoot.text = ConquerMaxChecker.externalRoot
        if ConquerMaxChecker.externalRoot == "" then
        (
            messageBox "请先点击 从MAX拾取 或选择目录。" title:"征服MAX模型检查器"
        )
        else
        (
            go = queryBox "将创建缺失的 C3、MAX、渲染图、渲染图/界面、设计稿文件夹；MAX 文件和 TGA 归入 MAX，当前打开的 MAX 会另存到 MAX 文件夹，DDS 归入 C3，PNG 归入渲染图/界面，JPG 归入渲染图。文件夹整理不会复制贴图到 C3；非贴图文件会移动到“不相关文件”，重名自动追加后缀。继续吗？" title:"征服MAX模型检查器"
            if go do
            (
                if ConquerMaxChecker.saveSceneToMaxFolder() and ConquerMaxChecker.runExternalHierarchyFix true then
                (
                    if ConquerMaxChecker.saveSceneToMaxFolder() then
                    (
                        if ConquerMaxChecker.runExternalCheck() then
                        (
                            edtPass.text = ConquerMaxChecker.externalPassText()
                            edtIssue.text = ConquerMaxChecker.externalIssueText()
                            displayModeText = "当前显示：外部文件检查"
                            externalStatusText = "外部层级已补全，MAX 已另存到 MAX 文件夹，并重新检查。"
                            refreshStatusText()
                        )
                        else
                        (
                            externalStatusText = "层级已补全，MAX 已另存，但重新检查失败"
                            refreshStatusText()
                            messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                        )
                    )
                    else
                    (
                        externalStatusText = "外部层级已补全，但 MAX 另存失败"
                        refreshStatusText()
                        messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                    )
                )
                else
                (
                    externalStatusText = "外部层级整理失败"
                    refreshStatusText()
                    messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                )
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on chkPSRefine changed state do
    (
        ConquerMaxChecker.psRefine = state
        try(setINISetting (psSettingsFile()) "DDS" "enabled" (state as string))catch()
    )
    on ddlPSVersion selected choiceIndex do selectPSVersion choiceIndex
    on btnConvertDDS pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local sourcePaths = #()
        local directDDSCount = 0
        local hasDDSMethods = false
        try
        (
            hasDDSMethods = true
            if not (isProperty ConquerMaxChecker #referencedDDSSourcePaths) do hasDDSMethods = false
            if not (isProperty ConquerMaxChecker #runDDSConversion) do hasDDSMethods = false
            if not (isProperty ConquerMaxChecker #rejectedPSDSourcePaths) do hasDDSMethods = false
        )
        catch(hasDDSMethods = false)

        if not hasDDSMethods then
        (
            messageBox "当前3ds Max仍加载旧版或不完整的检查器脚本。请关闭旧窗口后重新运行最新的 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
        )
        else
        (
            try
            (
                sourcePaths = ConquerMaxChecker.referencedDDSSourcePaths()
            )
            catch
            (
                sourcePaths = #()
                ConquerMaxChecker.lastError = "DDS贴图转换：收集材质贴图失败；" + (ConquerMaxChecker.exceptionText "未知错误")
            )

            if ConquerMaxChecker.rejectedPSDSourcePaths.count > 0 then
            (
                messageBox "PSD贴图不能转换DDS格式，也不能进入 C3。只允许TGA转换，请先将 MAX 材质中的 PSD 替换为 TGA。" title:"征服MAX模型检查器"
            )
            else if ConquerMaxChecker.lastError != "" then
                messageBox ConquerMaxChecker.lastError title:"生产贴图未就绪"
            else if sourcePaths.count == 0 then
            (
                try(directDDSCount = ConquerMaxChecker.directDDSReferenceCount())catch(directDDSCount = 0)
                if directDDSCount > 0 then
                    messageBox ("当前 MAX 已直接引用 " + (directDDSCount as string) + " 个 DDS 贴图，按规则跳过 DDS 转换，不会重复压缩。") title:"征服MAX模型检查器"
                else if ConquerMaxChecker.lastError != "" then
                    messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                else
                    messageBox "当前 MAX 检查范围内没有找到可转换的 TGA 贴图。\n请确认材质球或材质编辑器槽位中的 TGA 文件真实存在。" title:"征服MAX模型检查器"
            )
            else
            (
                externalStatusText = "外部状态：正在转换 MAX 实际引用的贴图..."
                refreshStatusText()
                try(windows.processPostedMessages())catch()

                try
                (
                    if ConquerMaxChecker.runDDSConversion sourcePaths then
                    (
                        edtIssue.text = ConquerMaxChecker.lastConversionText
                        externalStatusText = "外部状态：DDS 转换完成；已回读校验，MAX 保留 TGA"
                        refreshStatusText()
                    )
                    else
                    (
                        externalStatusText = "外部状态：MAX 贴图 DDS 转换失败"
                        refreshStatusText()
                        messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                    )
                )
                catch
                (
                    externalStatusText = "外部状态：MAX 贴图 DDS 转换报错"
                    refreshStatusText()
                    messageBox ("MAX 贴图 DDS 转换执行失败：\n" + (ConquerMaxChecker.exceptionText "未知错误")) title:"征服MAX模型检查器"
                )
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnConvertPNG pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local sourcePaths = #()
        local hasPNGMethods = false
        try
        (
            hasPNGMethods = true
            if not (isProperty ConquerMaxChecker #referencedDDSSourcePaths) do hasPNGMethods = false
            if not (isProperty ConquerMaxChecker #runPNGConversion) do hasPNGMethods = false
        )
        catch(hasPNGMethods = false)

        if not hasPNGMethods then
        (
            messageBox "当前脚本没有加载 PNG 转换功能，请重新加载 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
        )
        else
        (
            try(sourcePaths = ConquerMaxChecker.referencedDDSSourcePaths())catch(sourcePaths = #())
            if ConquerMaxChecker.lastError != "" then
                messageBox ConquerMaxChecker.lastError title:"生产贴图未就绪"
            else if sourcePaths.count == 0 then
            (
                messageBox "当前 MAX 材质没有找到可转换的 TGA 贴图。" title:"征服MAX模型检查器"
            )
            else
            (
                externalStatusText = "外部状态：正在把 MAX 实际引用的 TGA 转换为 PNG..."
                refreshStatusText()
                try(windows.processPostedMessages())catch()
                try
                (
                    if ConquerMaxChecker.runPNGConversion sourcePaths then
                        externalStatusText = "外部状态：PNG 转换完成，文件已写入 C3"
                    else
                        externalStatusText = "外部状态：TGA 转 PNG 失败"
                    edtIssue.text = ConquerMaxChecker.lastConversionText
                    refreshStatusText()
                )
                catch
                (
                    externalStatusText = "外部状态：TGA 转 PNG 报错"
                    refreshStatusText()
                    messageBox ("MAX 贴图 PNG 转换执行失败：\n" + (ConquerMaxChecker.exceptionText "未知错误")) title:"征服MAX模型检查器"
                )
                if ConquerMaxChecker.lastError != "" do
                    messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnOneClick pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local go = false
        local workflowOk = true
        local maxFixWarning = ""
        local stage = "初始化"
        local sourcePaths = #()
        local directDDSCount = 0
        local autoRoot = ""
        local placementError = ""
        local hasDDSMethods = false
        local progressDialogOpened = false
        ConquerMaxChecker.cancelRequested = false
        ConquerMaxChecker.externalRootManual = false

        try(placementError = ConquerMaxChecker.currentMaxPlacementError())catch(placementError = "")
        if placementError != "" do
        (
            externalStatusText = "外部状态：MAX 文件位置不符合整理要求"
            refreshStatusText()
            messageBox placementError title:"征服MAX模型检查器"
            return()
        )
        go = queryBox "将依次执行：MAX整理全流程、文件夹整理、DDS贴图转换、导出C3、生成渲染图、界面UI渲染。继续吗？" title:"征服MAX模型检查器"
        if go do
        (
            try(autoRoot = ConquerMaxChecker.currentMaxResourceRoot())catch(autoRoot = "")
            if autoRoot != "" do
            (
                ConquerMaxChecker.externalRoot = autoRoot
                edtExternalRoot.text = autoRoot
            )

            if ConquerMaxChecker.externalRoot == "" or not doesDirectoryExist ConquerMaxChecker.externalRoot then
            (
                messageBox "无法确定资源目录。请先点击“从MAX拾取”或“选择目录”。" title:"征服MAX模型检查器"
            )
            else
            (
                ConquerMaxChecker.silentSuccessMessages = true
                try
                (
                    try
                    (
                        createDialog conquerOneClickProgressRollout modal:false style:#(#style_titlebar, #style_sysmenu, #style_toolwindow)
                        progressDialogOpened = true
                    )
                    catch()
                    updateOneClickProgress 0 stageText:"准备一键出图..."
                    stage = "MAX整理全流程"
                    externalStatusText = "外部状态：正在执行 MAX 整理全流程..."
                    displayModeText = "当前显示：一键出图处理中"
                    refreshStatusText()
                    try(windows.processPostedMessages())catch()
                    updateOneClickProgress 8 stageText:"正在执行 MAX 整理全流程..."
                    workflowOk = ConquerMaxChecker.autoFix false
                    if not workflowOk and not (matchPattern ConquerMaxChecker.lastError pattern:"未能建立修改前备份*") and ConquerMaxChecker.fixErrors.count > 0 do
                    (
                        maxFixWarning = ConquerMaxChecker.lastError
                        workflowOk = true
                    )
                    if workflowOk do
                    (
                        undo off
                        (
                            ConquerMaxChecker.runAll()
                        )
                        try(clearUndoBuffer())catch()
                        try(setSaveRequired true)catch()
                        updateOneClickProgress 16 stageText:"MAX 整理全流程完成"
                    )

                    if workflowOk do
                    (
                        stage = "文件夹整理"
                        externalStatusText = "外部状态：正在整理文件夹..."
                        refreshStatusText()
                        try(windows.processPostedMessages())catch()
                        updateOneClickProgress 28 stageText:"正在整理文件夹..."
                        if matchPattern (ConquerMaxChecker.validateExternalRoot()) pattern:"*不通过*" then
                        (
                            ConquerMaxChecker.lastError = ConquerMaxChecker.validateExternalRoot()
                            workflowOk = false
                        )
                        else
                        (
                            if ConquerMaxChecker.saveSceneToMaxFolder() and ConquerMaxChecker.runExternalHierarchyFix true then
                            (
                                stage = "保存MAX"
                                externalStatusText = "外部状态：正在另存 MAX 到 MAX 文件夹..."
                                refreshStatusText()
                                try(windows.processPostedMessages())catch()
                                workflowOk = ConquerMaxChecker.saveSceneToMaxFolder()
                                if workflowOk do updateOneClickProgress 38 stageText:"MAX 已另存到 MAX 文件夹"
                            )
                            else
                                workflowOk = false
                        )
                    )

                    if workflowOk and maxFixWarning != "" do
                    (
                        workflowOk = false
                        stage = "文件整理已完成；MAX问题待修复，已跳过输出"
                        ConquerMaxChecker.lastError = stage + "\n" + maxFixWarning
                    )

                    if workflowOk do
                    (
                        stage = "文件夹检查"
                        externalStatusText = "外部状态：正在检查整理后的文件夹..."
                        refreshStatusText()
                        try(windows.processPostedMessages())catch()
                        updateOneClickProgress 46 stageText:"正在检查整理后的文件夹..."
                        if ConquerMaxChecker.runExternalCheck() then
                        (
                            edtPass.text = ConquerMaxChecker.externalPassText()
                            edtIssue.text = ConquerMaxChecker.externalIssueText()
                            updateOneClickProgress 54 stageText:"文件夹检查完成"
                        )
                        else
                            workflowOk = false
                    )

                    if workflowOk do
                    (
                        stage = "DDS贴图转换"
                        hasDDSMethods = false
                        try
                        (
                            hasDDSMethods = true
                            if not (isProperty ConquerMaxChecker #referencedDDSSourcePaths) do hasDDSMethods = false
                            if not (isProperty ConquerMaxChecker #runDDSConversion) do hasDDSMethods = false
                            if not (isProperty ConquerMaxChecker #rejectedPSDSourcePaths) do hasDDSMethods = false
                        )
                        catch(hasDDSMethods = false)

                        if not hasDDSMethods then
                        (
                            ConquerMaxChecker.lastError = "当前3ds Max仍加载旧版或不完整的检查器脚本，请关闭旧窗口后重新运行最新脚本。"
                            workflowOk = false
                        )
                        else
                        (
                            try
                            (
                                sourcePaths = ConquerMaxChecker.referencedDDSSourcePaths()
                            )
                            catch
                            (
                                sourcePaths = #()
                                ConquerMaxChecker.lastError = "DDS贴图转换：收集材质贴图失败；" + (ConquerMaxChecker.exceptionText "未知错误")
                                workflowOk = false
                            )

                            if ConquerMaxChecker.lastError != "" do workflowOk = false
                            if workflowOk and ConquerMaxChecker.rejectedPSDSourcePaths.count > 0 then
                            (
                                ConquerMaxChecker.lastError = "PSD贴图不能转换DDS格式，也不能进入 C3。只允许TGA转换，请先将 MAX 材质中的 PSD 替换为 TGA。"
                                workflowOk = false
                            )
                            else if workflowOk and sourcePaths.count > 0 then
                            (
                                externalStatusText = "外部状态：正在转换 DDS 贴图..."
                                refreshStatusText()
                                try(windows.processPostedMessages())catch()
                                updateOneClickProgress 64 stageText:"正在转换 DDS 贴图..."
                                try
                                (
                                    if ConquerMaxChecker.runDDSConversion sourcePaths then
                                    (
                                        externalStatusText = "外部状态：DDS 已写入 C3；MAX 材质保留 TGA"
                                        updateOneClickProgress 72 stageText:"DDS 贴图转换完成"
                                    )
                                    else
                                    (
                                        ConquerMaxChecker.lastError = "DDS贴图转换失败。" + (if ConquerMaxChecker.lastError != "" then "\n" + ConquerMaxChecker.lastError else "")
                                        workflowOk = false
                                    )
                                )
                                catch
                                (
                                    ConquerMaxChecker.lastError = "DDS贴图转换执行异常；" + (ConquerMaxChecker.exceptionText "未知错误")
                                    workflowOk = false
                                )
                            )
                            else if workflowOk then
                            (
                                try(directDDSCount = ConquerMaxChecker.directDDSReferenceCount())catch(directDDSCount = 0)
                                if directDDSCount > 0 then
                                    externalStatusText = "外部状态：材质已直接引用 DDS，按规则跳过转换"
                                else
                                    externalStatusText = "外部状态：未找到 TGA 生产材质贴图，跳过 DDS 转换"
                            )
                        )
                        refreshStatusText()
                    )

                    if workflowOk do
                    (
                        stage = "导出 C3"
                        externalStatusText = "外部状态：正在导出 C3..."
                        refreshStatusText()
                        try(windows.processPostedMessages())catch()
                        workflowOk = ConquerMaxChecker.exportC3Objects()
                        if workflowOk do updateOneClickProgress 84 stageText:"C3 导出完成"
                    )

                    if workflowOk do
                    (
                        stage = "生成渲染图"
                        externalStatusText = "外部状态：正在生成渲染图..."
                        refreshStatusText()
                        try(windows.processPostedMessages())catch()
                        workflowOk = ConquerMaxChecker.renderPreviewImage()
                        if workflowOk do updateOneClickProgress 92 stageText:"自动渲染图完成"
                    )

                    if workflowOk do
                    (
                        stage = "界面UI渲染"
                        externalStatusText = "外部状态：正在生成界面 UI PNG..."
                        refreshStatusText()
                        try(windows.processPostedMessages())catch()
                        workflowOk = ConquerMaxChecker.renderInterfaceUI()
                        if workflowOk do updateOneClickProgress 100 stageText:"界面 UI 渲染完成"
                    )
                )
                catch
                (
                    workflowOk = false
                    ConquerMaxChecker.lastError = "一键出图失败，阶段：" + stage + "；" + (ConquerMaxChecker.exceptionText "未知错误")
                )
                if progressDialogOpened do
                (
                    try(destroyDialog conquerOneClickProgressRollout)catch()
                    progressDialogOpened = false
                )
                ConquerMaxChecker.silentSuccessMessages = false

                if workflowOk then
                (
                    externalStatusText = if ConquerMaxChecker.lastError == "" then "一键出图完成；输出已生成" else "一键出图部分完成，请查看失败项"
                    if ConquerMaxChecker.lastError != "" do edtIssue.text = ConquerMaxChecker.lastError
                    displayModeText = "当前显示：渲染图和界面 UI PNG 已生成"
                    refreshStatusText()
                )
                else
                (
                    externalStatusText = "外部状态：一键出图失败"
                    displayModeText = "当前显示：流程失败，阶段：" + stage
                    edtIssue.text = ConquerMaxChecker.lastError + "\r\n\r\n" + ConquerMaxChecker.reportIssueText()
                    refreshStatusText()
                    messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
                )
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnShowMax pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        if ConquerMaxChecker.report.count == 0 do
            ConquerMaxChecker.runAll()
        edtPass.text = ConquerMaxChecker.reportPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText()
        displayModeText = "当前显示：MAX 内部检查"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnShowExternal pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        if ConquerMaxChecker.externalOutput == "" or not doesFileExist (ConquerMaxChecker.externalCsvPath()) then
        (
            messageBox "请先点击“外部检查”。" title:"征服MAX模型检查器"
        )
        else
        (
            edtPass.text = ConquerMaxChecker.externalPassText()
            edtIssue.text = ConquerMaxChecker.externalIssueText()
            displayModeText = "当前显示：外部文件检查"
            refreshStatusText()
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnShowMerged pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        if ConquerMaxChecker.report.count == 0 do
            ConquerMaxChecker.runAll()
        edtPass.text = ConquerMaxChecker.reportPassText() + ConquerMaxChecker.externalPassText()
        edtIssue.text = ConquerMaxChecker.reportIssueText() + ConquerMaxChecker.externalIssueText()
        displayModeText = "当前显示：MAX 内部 + 外部文件"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnOpenMaxParent pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        if ConquerMaxChecker.openMaxParentFolder() then
        (
            edtExternalRoot.text = ConquerMaxChecker.externalRoot
            externalStatusText = "已打开当前 MAX 整理目录；" + ConquerMaxChecker.validateExternalRoot()
            refreshStatusText()
        )
        else
        (
            externalStatusText = "打开当前 MAX 整理目录失败"
            refreshStatusText()
            messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnClear pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        ConquerMaxChecker.resetReport()
        edtPass.text = ""
        edtIssue.text = ""
        displayModeText = "当前显示：已清空"
        refreshStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnFullFix pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local go = queryBox "将自动修改环境、模型、贴图材质、相机/灯光/辅助对象/骨骼与动画信息，并在最后重置变换后塌陷。继续吗？" title:"征服MAX模型检查器"
        if go do
        (
            local deleteBase = false
            local autoFixOk = false
            try(ConquerMaxChecker.refreshImportedBaseState())catch()
            -- 基础体默认保留；专用“移除基础体”按钮负责删除。
            autoFixOk = ConquerMaxChecker.autoFix deleteBase
            lblBaseDims.text = ConquerMaxChecker.baseStatusText()
            /*
                自动修改完成后仍需要重新检查一次；这一步也可能触碰对象显示属性，
                因此必须和自动修改使用同一套撤销保护，清空后不再留下新撤销记录。
            */
            undo off
            (
                ConquerMaxChecker.runAll()
            )
            try(clearUndoBuffer())catch()
            try(setSaveRequired true)catch()
            edtPass.text = ConquerMaxChecker.reportPassText()
            edtIssue.text = ConquerMaxChecker.reportIssueText()
            displayModeText = "当前显示：MAX 内全修改后检查"
            refreshStatusText()
            if autoFixOk then
                displayModeText = "全部修复完成；原场景已备份，模型操作的撤销历史已清空"
            else
                displayModeText = "部分修复失败；查看右侧详情，原场景已有备份"
            refreshStatusText()
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnExportC3 pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local hasC3Method = false
        try(hasC3Method = isProperty ConquerMaxChecker #exportC3Objects)catch()
        if not hasC3Method then
        (
            messageBox "当前3ds Max中仍加载的是旧版检查器脚本。请关闭当前检查器窗口后，重新运行最新的 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
        )
        else
        (
            try
            (
                ConquerMaxChecker.exportC3Objects()
            )
            catch
            (
                messageBox ("C3 导出执行失败：\n" + (ConquerMaxChecker.exceptionText "未知错误")) title:"征服MAX模型检查器"
            )
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnRenderPreview pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local hasRenderMethod = false
        try(hasRenderMethod = isProperty ConquerMaxChecker #renderPreviewImage)catch()
        if not hasRenderMethod then
        (
            messageBox "当前3ds Max中仍加载的是旧版检查器脚本。请关闭当前检查器窗口后，重新运行最新的 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
        )
        else
        (
            displayModeText = "当前显示：正在生成渲染图..."
            refreshStatusText()
            try(windows.processPostedMessages())catch()
            try
            (
                if ConquerMaxChecker.renderPreviewImage() then
                    displayModeText = "当前显示：渲染图已生成"
                else
                    displayModeText = "当前显示：渲染图生成失败"
            )
            catch
            (
                displayModeText = "当前显示：渲染图报错"
                messageBox ("渲染图执行失败：\n" + (ConquerMaxChecker.exceptionText "未知错误")) title:"征服MAX模型检查器"
            )
            refreshStatusText()
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnRenderInterface pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        local hasInterfaceRenderMethod = false
        try(hasInterfaceRenderMethod = isProperty ConquerMaxChecker #renderInterfaceUI)catch()
        if not hasInterfaceRenderMethod then
        (
            messageBox "当前3ds Max中仍加载的是旧版检查器脚本。请关闭当前检查器窗口后，重新运行最新的 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
        )
        else
        (
            displayModeText = "当前显示：正在生成界面 UI PNG..."
            refreshStatusText()
            try(windows.processPostedMessages())catch()
            try
            (
                if ConquerMaxChecker.renderInterfaceUI() then
                    displayModeText = "当前显示：界面 UI PNG 已生成"
                else
                    displayModeText = "当前显示：界面 UI PNG 生成失败"
            )
            catch
            (
                displayModeText = "当前显示：界面 UI PNG 报错"
                messageBox ("界面 UI 渲染执行失败：\n" + (ConquerMaxChecker.exceptionText "未知错误")) title:"征服MAX模型检查器"
            )
            refreshStatusText()
            if ConquerMaxChecker.lastError != "" and displayModeText == "当前显示：界面 UI PNG 已生成" do
                messageBox ConquerMaxChecker.lastError title:"征服MAX模型检查器"
        )
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )

    on btnRemoveBase pressed do
    (
        if ConquerMaxChecker.busy then return()
        setBusy true
        fn performAction =
        (
        if ConquerMaxChecker.importedBaseNodes.count == 0 then
            messageBox "当前没有基础体。" title:"基础体观察"
        else ConquerMaxChecker.removeImportedBaseBody()
        lblBaseDims.text = ConquerMaxChecker.baseStatusText()
    
        )
        try(performAction())catch(messageBox (ConquerMaxChecker.exceptionText "操作失败") title:"征服MAX")
        setBusy false
    )
)

try(destroyDialog conquerCheckerRollout)catch()
createDialog conquerCheckerRollout

/* 打开检查器时，若当前 MAX 已保存且位于资源包的 MAX 文件夹内，自动带出资源主文件夹。 */
try
(
    local autoRoot = ConquerMaxChecker.currentMaxResourceRoot()
    if autoRoot != "" do
    (
        ConquerMaxChecker.externalRoot = autoRoot
        conquerCheckerRollout.edtExternalRoot.text = autoRoot
        conquerCheckerRollout.externalStatusText = "已自动拾取当前 MAX 文件夹；" + ConquerMaxChecker.validateExternalRoot()
        conquerCheckerRollout.refreshStatusText()
    )
)
catch()


