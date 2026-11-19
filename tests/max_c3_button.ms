/* Run only in a disposable Max process; all assets are created under .build. */
(
    global ConquerMaxChecker
    global conquerCheckerRollout
    global c3ButtonMessages = #()
    global captureC3ButtonMessage
    fn captureC3ButtonMessage text title:"" = (append c3ButtonMessages text; true)
    local root = (dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName())) + "..\\")
    local runId = (dotNetClass "System.Guid").NewGuid()
    local sandbox = root + ".build\\c3-button-" + runId.ToString()
    (dotNetClass "System.IO.Directory").CreateDirectory (sandbox + "\\MAX")
    local log = createFile (root + ".build\\c3-button-result.txt")
    try
    (
        resetMaxFile #noPrompt
        local source = (dotNetClass "System.IO.File").ReadAllText (root + "ConquerMaxChecker\\ConquerMaxChecker.ms")
        execute (substituteString source "messageBox" "captureC3ButtonMessage")
        local texture = sandbox + "\\MAX\\fixture.tga"
        local bm = bitmap 64 64 color:(color 100 150 200) filename:texture
        save bm
        close bm
        local node = box name:"c3_button_fixture" mapcoords:true
        convertToPoly node
        node.material = standardMaterial name:"fixture_material"
        node.material.diffuseMap = bitmapTexture filename:texture
        saveMaxFile (sandbox + "\\MAX\\fixture.max") quiet:true
        select node
        local oldRange = animationRange
        local oldTime = sliderTime
        c3ButtonMessages = #()
        conquerCheckerRollout.btnExportC3.pressed()
        local target = sandbox + "\\C3\\fixture.c3"
        if not doesFileExist target do throw ("No C3 output: " + ConquerMaxChecker.lastError)
        if getFileSize target <= 0 do throw "Empty C3 output"
        if c3ButtonMessages.count != 1 do throw "Expected exactly one success dialog"
        if not matchPattern c3ButtonMessages[1] pattern:"C3 已导出 1 个*fixture.c3*" do throw c3ButtonMessages[1]
        if not matchPattern conquerCheckerRollout.edtIssue.text pattern:"C3 已导出 1 个*fixture.c3*" do throw ("Missing persistent output details: " + conquerCheckerRollout.edtIssue.text)
        if ConquerMaxChecker.busy or not conquerCheckerRollout.btnExportC3.enabled do throw "Button stayed busy"
        if ConquerMaxChecker.silentSuccessMessages do throw "Silent flag leaked"
        if selection.count != 1 or selection[1] != node do throw "Selection changed"
        if animationRange.start != oldRange.start or animationRange.end != oldRange.end or sliderTime != oldTime do throw ("Time range changed: " + (oldRange as string) + " -> " + (animationRange as string))
        format "SUCCESS_BUTTON_OK: %\n" target to:log
        flush log

        ConquerMaxChecker.selectedOnly = true
        local excluded = box name:"unselected_without_material"
        select node
        c3ButtonMessages = #()
        conquerCheckerRollout.btnExportC3.pressed()
        if c3ButtonMessages.count != 1 do throw "Expected selected export dialog"
        if not matchPattern c3ButtonMessages[1] pattern:"C3 已导出 1 个*fixture.c3*" do throw c3ButtonMessages[1]
        format "SELECTED_EXPORT_OK\n" to:log
        flush log
        ConquerMaxChecker.silentSuccessMessages = true
        clearSelection()
        c3ButtonMessages = #()
        conquerCheckerRollout.btnExportC3.pressed()
        if c3ButtonMessages.count != 1 do throw "Expected exactly one failure dialog"
        if not matchPattern c3ButtonMessages[1] pattern:"*没有选中的生产几何对象*" do throw c3ButtonMessages[1]
        if conquerCheckerRollout.edtIssue.text != c3ButtonMessages[1] do throw "Failure details missing"
        if ConquerMaxChecker.lastC3ExportText != "" do throw "Stale success summary"
        if ConquerMaxChecker.busy or not conquerCheckerRollout.btnExportC3.enabled do throw "Failed button stayed busy"
        if not ConquerMaxChecker.silentSuccessMessages do throw "Previous silent flag not restored"
        format "NO_SELECTION_FAILURE_OK\nPASS\n" to:log
    )
    catch(format "FAIL: %\n" (getCurrentException() as string) to:log)
    close log
    quitMax #noPrompt
)
