global ConquerMaxChecker
global ConquerMaxCheckerStruct
global testLog = createFile @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\max-smoke.log"
fn record value = (format "%\n" value to:testLog; flush testLog)
record "START"
global testOldAutoback = getDir #autoback
makeDir @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\test-autoback"
setDir #autoback @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\test-autoback"
try
(
    fileIn @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\ConquerMaxChecker\ConquerMaxChecker.ms"
    record "LOAD_OK"
    resetMaxFile #noPrompt
    ConquerMaxChecker = ConquerMaxCheckerStruct()
    local node = box name:"test_model" pos:[12,4,3] mapcoords:true
    convertToPoly node
    local reference = box name:"baseObs_1" pos:[20,20,20]
    ConquerMaxChecker.refreshImportedBaseState()
    if (ConquerMaxChecker.getGeometryNodes()).count != 1 do throw "base scope failed"
    record "SCOPE_OK"
    ConquerMaxChecker.runAll()
    record ("CHECK_OK " + ConquerMaxChecker.report.count as string)
    ConquerMaxChecker.fixGeometry()
    ConquerMaxChecker.finalResetTransformAndCollapse()
    if distance node.pos [0,0,0] > 0.001 do throw "origin failed"
    if distance reference.pos [20,20,20] > 0.001 do throw "base changed"
    record "MODEL_OK"
    ConquerMaxChecker.fixRenderSettings()
    record (classOf renderers.production.antiAliasFilter as string)
    if classOf renderers.production.antiAliasFilter != Area do throw "Area filter failed"
    if abs(renderers.production.antiAliasFilterSize - 1.5) > 0.001 do throw "filter size failed"
    record "RENDER_SETTINGS_OK"
    local fixture = @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\MaxFixture\资源\MAX\"
    local source = fixture + "alpha.tga"
    saveMaxFile (fixture + "test.max") quiet:true
    local mat = standardMaterial name:"wrong_material"
    mat.diffuseMap = bitmapTexture filename:source
    node.material = mat
    record ("ROOT " + ConquerMaxChecker.currentMaxResourceRoot())
    if not ConquerMaxChecker.fixMaterialOnly() do
    (
        for err in ConquerMaxChecker.fixErrors do record err.detail
        throw "material fix failed"
    )
    record "MATERIAL_FIX_OK"
    if mat.opacityMap == undefined or mat.opacityMap == mat.diffuseMap do throw "alpha copy failed"
    if mat.diffuseMap.filename != "alpha.tga" do throw "path strip failed"
    local oldOpacity = mat.opacityMap
    ConquerMaxChecker.fixMaterialSettings()
    if mat.opacityMap != oldOpacity do throw "opacity recreated on repeat"
    record "MATERIAL_REPEAT_OK"
    if not doesFileExist ConquerMaxChecker.lastBackup do throw "backup missing"
    record "BACKUP_OK"
    ConquerMaxChecker.runMaterialCheck()
    for item in ConquerMaxChecker.report where item.status != "通过" do record (item.category + " " + item.detail)
    local sources = ConquerMaxChecker.referencedDDSSourcePaths()
    record ("SOURCES " + sources.count as string + " " + ConquerMaxChecker.lastError)
    if sources.count != 1 do throw "production input scan failed"
    if not ConquerMaxChecker.runPNGConversion sources do throw ConquerMaxChecker.lastError
    record "PNG_MAX_CHAIN_OK"
    local beforeName = mat.diffuseMap.filename
    mat.diffuseMap.filename = fixture + "missing.psd"
    ConquerMaxChecker.normalizeProductionTextureExtensionsToTga()
    if mat.diffuseMap.filename != fixture + "missing.psd" do throw "fake TGA reference"
    mat.diffuseMap.filename = beforeName
    ConquerMaxChecker.fixErrors = #()
    if not ConquerMaxChecker.fixModelOnly() do
    (
        for err in ConquerMaxChecker.fixErrors do record err.detail
        throw "model fix failed"
    )
    record "NORMALS_FIX_OK"
    if not ConquerMaxChecker.runDDSConversion (ConquerMaxChecker.referencedDDSSourcePaths()) do throw ConquerMaxChecker.lastError
    record "DDS_MAX_CHAIN_OK"
    ConquerMaxChecker.silentSuccessMessages = true
    if not ConquerMaxChecker.renderPreviewImage() do throw ConquerMaxChecker.lastError
    record "PREVIEW_RENDER_OK"
    if not ConquerMaxChecker.renderInterfaceUI() do throw ConquerMaxChecker.lastError
    record "UI_RENDER_OK"
    if not ConquerMaxChecker.autoFix false do
    (
        for err in ConquerMaxChecker.fixErrors do record err.detail
        throw "full fix failed"
    )
    ConquerMaxChecker.runAll()
    for item in ConquerMaxChecker.report where item.category == "报错" do record item.detail
    record "FULL_FIX_OK"
    delete reference
    if not ConquerMaxChecker.exportC3Objects() do throw ConquerMaxChecker.lastError
    record "C3_EXPORT_OK"
    if not ConquerMaxChecker.exportC3Objects() do throw ConquerMaxChecker.lastError
    record "C3_OVERWRITE_OK"
    if not ConquerMaxChecker.runExternalHierarchyFix true do throw ConquerMaxChecker.lastError
    record "HIERARCHY_MAX_CHAIN_OK"
    if not ConquerMaxChecker.runExternalCheck() do throw ConquerMaxChecker.lastError
    record "CHECK_MAX_CHAIN_OK"
    record "PASS"
)
catch(record ("FAIL " + getCurrentException() as string); try(record (getCurrentExceptionStackTrace()))catch())
setDir #autoback testOldAutoback
close testLog
quitMAX #noPrompt
