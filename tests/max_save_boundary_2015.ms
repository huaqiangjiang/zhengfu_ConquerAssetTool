global ConquerMaxChecker
global boundaryLog = createFile @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\max-save-boundary.log"
fn boundaryRecord value = (format "%\n" value to:boundaryLog; flush boundaryLog)
boundaryRecord "START"
global boundaryOldAutoback = getDir #autoback
setDir #autoback @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\test-autoback"
try
(
    fileIn @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\ConquerMaxChecker\ConquerMaxChecker.ms"
    local root = @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\SaveBoundary-" + ConquerMaxChecker.newRunId()
    local dirAPI = dotNetClass "System.IO.Directory"
    local fileAPI = dotNetClass "System.IO.File"
    dirAPI.CreateDirectory (root + "\\MAX")
    local source = root + "\\asset.max"
    local target = root + "\\MAX\\asset.max"
    local node = box name:"boundary_model"
    if not saveMaxFile source quiet:true do throw "fixture save failed"
    fileAPI.Copy source target false
    fileAPI.Copy source (root + "\\MAX\\asset_2.max") false
    node.pos = [1,2,3]
    if not ConquerMaxChecker.saveSceneToMaxFolder() do throw ConquerMaxChecker.lastError
    if toLower (maxFilePath + maxFileName) != toLower target do throw "active save path incorrect"
    boundaryRecord "ACTIVE_PATH_SWITCH_OK"
    if not ConquerMaxChecker.runExternalHierarchyFix true do throw ConquerMaxChecker.lastError
    local files = getFiles (root + "\\MAX\\*.max")
    if files.count != 1 or toLower files[1] != toLower target do throw "more than one delivery MAX"
    if doesFileExist source do throw "old source not archived"
    boundaryRecord "SINGLE_MAX_OK"
    node.pos = [9,8,7]
    max file save
    if toLower (maxFilePath + maxFileName) != toLower target do throw "normal save changed path"
    if (getFiles (root + "\\MAX\\*.max")).count != 1 do throw "normal save created extra MAX"
    if not loadMaxFile target quiet:true do throw "reload failed"
    local loaded = getNodeByName "boundary_model"
    if loaded == undefined or distance loaded.pos [9,8,7] > 0.001 do throw "normal save did not update same file"
    boundaryRecord "NORMAL_SAVE_AND_RELOAD_OK"
    if not ConquerMaxChecker.saveSceneToMaxFolder() do throw ConquerMaxChecker.lastError
    if not ConquerMaxChecker.runExternalHierarchyFix true do throw ConquerMaxChecker.lastError
    if (getFiles (root + "\\MAX\\*.max")).count != 1 do throw "repeat created extra MAX"
    boundaryRecord "REPEAT_OK"
    boundaryRecord "PASS"
)
catch(boundaryRecord ("FAIL " + getCurrentException() as string))
setDir #autoback boundaryOldAutoback
close boundaryLog
quitMAX #noPrompt
