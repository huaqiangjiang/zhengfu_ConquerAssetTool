/* Run in a disposable Max instance. An optional test TGA is copied before use. */
(
    global ConquerMaxChecker
    global conquerCheckerRollout
    global ConquerPendingDDSJob
    local root = (dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName())) + "..\\")
    local id = (dotNetClass "System.Guid").NewGuid()
    local sandbox = root + ".build\\png-button-" + id.ToString()
    (dotNetClass "System.IO.Directory").CreateDirectory (sandbox + "\\MAX")
    local log = createFile (root + ".build\\png-button-result.txt")
    try
    (
        resetMaxFile #noPrompt
        fileIn (root + "ConquerMaxChecker\\ConquerMaxChecker.ms")
        local texture = sandbox + "\\MAX\\fixture.tga"
        local source = (dotNetClass "System.Environment").GetEnvironmentVariable "CONQUER_TEST_TGA"
        if source != undefined and source != "" then
            (dotNetClass "System.IO.File").Copy source texture
        else
        (
            local bm = bitmap 64 64 color:(color 100 150 200) filename:texture
            save bm
            close bm
        )
        local node = box mapcoords:true
        node.material = standardMaterial()
        node.material.diffuseMap = bitmapTexture filename:texture
        saveMaxFile (sandbox + "\\MAX\\fixture.max") quiet:true
        ConquerMaxChecker.psRefine = (source != undefined and source != "")
        ConquerMaxChecker.psVersion = "2019"
        local started = timeStamp()
        conquerCheckerRollout.btnConvertPNG.pressed()
        if ConquerPendingDDSJob == undefined or not ConquerMaxChecker.busy do throw "Button did not return with a pending job"
        local job = ConquerPendingDDSJob
        format "BUTTON_RETURN_MS=% PID=% REPORT=%\n" (timeStamp()-started) job.process.Id job.reportFolder to:log
        flush log
        conquerCheckerRollout.btnConvertPNG.pressed()
        if ConquerPendingDDSJob.reportFolder != job.reportFolder do throw "Duplicate launch"
        while ConquerMaxChecker.busy and (timeStamp()-started < 200000) do
        (
            windows.processPostedMessages()
            sleep 0.05
        )
        if ConquerPendingDDSJob != undefined or ConquerMaxChecker.busy do throw "Completion was not reported"
        if not conquerCheckerRollout.btnConvertPNG.enabled do throw "Button stayed disabled"
        if ConquerMaxChecker.lastError != "" do throw ConquerMaxChecker.lastError
        if not matchPattern conquerCheckerRollout.lblStatus.text pattern:"*PNG 转换完成*" do throw "Missing completion status"
        if not doesFileExist (sandbox + "\\C3\\fixture.png") do throw "Missing PNG"
        (dotNetClass "System.IO.File").Copy (sandbox + "\\C3\\fixture.png") (sandbox + "\\refined.png")
        format "SANDBOX=%\n" sandbox to:log
        ConquerMaxChecker.psRefine = false
        if not (ConquerMaxChecker.runPNGConversion #(texture)) do throw ConquerMaxChecker.lastError
        format "SYNC_PNG_OK\nPASS\n" to:log
    )
    catch(format "FAIL: %\n" (getCurrentException() as string) to:log)
    close log
    quitMax #noPrompt
)
