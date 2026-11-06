/* Disposable Max process. Optional .build/process-test-root.txt selects a read-only resource check. */
(
    global ConquerMaxChecker
    local root = (dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName())) + "..\\")
    local output = root + ".build\\process-wait-result.txt"
    local resourceFile = root + ".build\\process-test-root.txt"
    fn recordProcessTest path text = ((dotNetClass "System.IO.File").AppendAllText path (text + "\r\n"))
    (dotNetClass "System.IO.File").WriteAllText output "START\r\n"
    try
    (
        local resource = ""
        if doesFileExist resourceFile do resource = trimRight ((dotNetClass "System.IO.File").ReadAllText resourceFile) "\r\n"
        if resource != "" do
        (
            local scenes = getFiles (resource + "\\MAX\\*.max")
            if scenes.count > 0 do loadMaxFile scenes[1] quiet:true
        )
        fileIn (root + "ConquerMaxChecker\\ConquerMaxChecker.ms")
        for i = 1 to 3 do
        (
            local timer = (dotNetClass "System.Diagnostics.Stopwatch").StartNew()
            local log = root + ".build\\process-wait-" + (i as string) + ".log"
            local code = ConquerMaxChecker.runExternalProcess (root + "ConquerMaxChecker\\ConquerAssetTool.exe") "--version" log
            timer.Stop()
            if code != 0 do throw "Version child process failed"
            if not matchPattern ((dotNetClass "System.IO.File").ReadAllText log) pattern:"*END exit=0*" do throw "Missing completed log"
            recordProcessTest output ("VERSION_SECONDS=" + (timer.Elapsed.TotalSeconds as string))
            if timer.Elapsed.TotalSeconds > 30 do throw "Process wait exceeded 30 seconds"
        )
        if resource != "" do
        (
            ConquerMaxChecker.externalRootManual = true
            ConquerMaxChecker.externalRoot = resource
            local timer = (dotNetClass "System.Diagnostics.Stopwatch").StartNew()
            if not ConquerMaxChecker.runExternalCheck() do throw ConquerMaxChecker.lastError
            timer.Stop()
            recordProcessTest output ("CHECK_SECONDS=" + (timer.Elapsed.TotalSeconds as string))
            if timer.Elapsed.TotalSeconds > 30 do throw "Resource check exceeded 30 seconds"
        )
        recordProcessTest output "PASS"
    )
    catch(recordProcessTest output ("FAIL: " + (getCurrentException() as string)))
    quitMax #noPrompt
)
