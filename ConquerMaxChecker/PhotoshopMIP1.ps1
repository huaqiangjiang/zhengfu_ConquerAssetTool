param([Parameter(Mandatory=$true)][string]$JobPath, [string]$ProgId='Photoshop.Application.10')
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$jobText=Get-Content -LiteralPath $JobPath -Raw -Encoding UTF8
$jobText | ConvertFrom-Json | Out-Null
$template=@'
(function(job){
 var previous=app.displayDialogs, original=app.documents.length?app.activeDocument:null;
 var opened=[];
 app.displayDialogs=DialogModes.NO;
 function own(file){
  var f=new File(file);
  for(var i=0;i<app.documents.length;i++){
   var existing='';try{existing=app.documents[i].fullName.fsName;}catch(e){}
   if(existing.toLowerCase()==f.fsName.toLowerCase())throw Error('File already open in Photoshop; save/close it before processing: '+file);
  }
  var d=app.open(f);opened.push(d);return d;
 }
 function rgb(d){app.activeDocument=d;d.activeChannels=[d.channels[0],d.channels[1],d.channels[2]];}
 function pasteAt(d,x,y){
  rgb(d); var layer=d.paste();
  layer.translate(UnitValue(x-layer.bounds[0].as('px'),'px'),UnitValue(y-layer.bounds[1].as('px'),'px'));
  return layer;
 }
 try {
  if(job.expectedMajor && parseInt(app.version,10)!=job.expectedMajor)throw Error('Photoshop version mismatch: '+app.version);
  var source=own(job.tga);
  if(source.width.as('px')!=job.width||source.height.as('px')!=job.height)throw Error('TGA dimensions mismatch');
  source.flatten();
  source.resizeImage(UnitValue(job.halfWidth,'px'),UnitValue(job.halfHeight,'px'),null,ResampleMethod.BICUBIC);
  rgb(source);source.activeLayer.applySharpen();
  var options=new TargaSaveOptions();options.alphaChannels=true;options.rleCompression=false;
  options.resolution=source.channels.length>3?TargaBitsPerPixels.THIRTYTWO:TargaBitsPerPixels.TWENTYFOUR;
  source.saveAs(new File(job.halfTga),options,true,Extension.LOWERCASE);
  var strip=own(job.strip);
  if(strip.height.as('px')!=job.height||strip.width.as('px')<job.width+job.halfWidth)
   throw Error('Enable NVIDIA DDS Load MIP maps; expected horizontal mip strip');
  rgb(source);source.selection.selectAll();source.selection.copy();source.selection.deselect();
  pasteAt(strip,job.width,0);
  strip.saveAs(new File(job.proof),new PNGSaveOptions(),true,Extension.LOWERCASE);
  // Encode only the edited mip. Re-encoding the full DDS would alter mip0.
  var target=own(job.template);
  target.crop([UnitValue(0,'px'),UnitValue(0,'px'),UnitValue(job.halfWidth,'px'),UnitValue(job.halfHeight,'px')]);
  rgb(source);source.selection.selectAll();source.selection.copy();source.selection.deselect();
  pasteAt(target,0,0);target.flatten();
  rgb(target);
  while(target.channels.length>3)target.channels[target.channels.length-1].remove();
  if(source.channels.length>3){app.activeDocument=source;source.channels[3].duplicate(target);}
  rgb(target);
  // Explicit legacy NVIDIA options: encode exactly one PS-sharpened level.
  // DXT1=0, DXT3=2, DXT5=3; mip mode 32=no mip generation.
  var fmt={DXT1:0,DXT3:2,DXT5:3}[job.fourcc];
  if(fmt===undefined)throw Error('Unsupported DDS format '+job.fourcc);
  var codec=new ActionDescriptor();
  codec.putInteger(charIDToTypeID('txfm'),fmt);
  codec.putInteger(charIDToTypeID('mmty'),32);
  codec.putInteger(charIDToTypeID('tmty'),0);
  codec.putBoolean(charIDToTypeID('prem'),false);
  codec.putBoolean(charIDToTypeID('bina'),false);
  codec.putBoolean(charIDToTypeID('nmcv'),false);
  var save=new ActionDescriptor();
  save.putObject(charIDToTypeID('As  '),stringIDToTypeID('NVIDIA D3D/DDS'),codec);
  save.putPath(charIDToTypeID('In  '),new File(job.template));
  executeAction(charIDToTypeID('save'),save,DialogModes.NO);
  return 'PHOTOSHOP_MIP1_OK '+job.dds;
 } catch(error) { return 'ERROR '+error.toString(); } finally {
  for(var i=opened.length-1;i>=0;i--){try{opened[i].close(SaveOptions.DONOTSAVECHANGES);}catch(e){}}
  app.displayDialogs=previous;
  if(original){try{app.activeDocument=original;}catch(e){}}
 }
})(__JOB__);
'@
$script=$template.Replace('__JOB__',$jobText)
$app=New-Object -ComObject $ProgId
$mutex=New-Object System.Threading.Mutex($false,'Local\ConquerPhotoshopMIP1')
if(-not $mutex.WaitOne(0)){ $mutex.Dispose(); throw 'Photoshop mip1 task already running' }
try { $result=$app.DoJavaScript($script) } finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
if($result -notlike 'PHOTOSHOP_MIP1_OK *'){throw $result}
$job=$jobText|ConvertFrom-Json
$bytes=[IO.File]::ReadAllBytes($job.template)
if($bytes.Length -lt 128 -or [Text.Encoding]::ASCII.GetString($bytes,0,4) -ne 'DDS '){throw 'Photoshop DDS export is empty/invalid; do not commit'}
if([BitConverter]::ToUInt32($bytes,16) -ne $job.halfWidth -or [BitConverter]::ToUInt32($bytes,12) -ne $job.halfHeight){throw 'DDS mip1 dimensions mismatch; do not commit'}
$actualFormat=[Text.Encoding]::ASCII.GetString($bytes,84,4)
if($actualFormat -ne $job.fourcc){throw ('PS导出格式不符：需要 '+$job.fourcc+'，实际 '+$actualFormat)}
$result
