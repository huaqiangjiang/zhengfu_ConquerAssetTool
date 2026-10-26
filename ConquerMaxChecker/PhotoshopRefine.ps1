param([Parameter(Mandatory=$true)][string]$JobPath, [string]$ProgId='Photoshop.Application')
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$jobText=Get-Content -LiteralPath $JobPath -Raw -Encoding UTF8
$jobText | ConvertFrom-Json | Out-Null
$template=@'
(function(job){
 var dialogs=app.displayDialogs, units=app.preferences.rulerUnits;
 var original=app.documents.length?app.activeDocument:null, opened=[], adapter=null, methods=[];
 var c=charIDToTypeID;
 function own(d){opened.push(d);return d;}
 function rgb(d){app.activeDocument=d;d.activeChannels=[d.channels[0],d.channels[1],d.channels[2]];}
 function read(file){
  var f=new File(file);f.encoding='BINARY';if(!f.open('r'))throw Error('Cannot read '+file);
  var b=f.read();f.close();return b;
 }
 function u32(b,i){return (b.charCodeAt(i)&255)+(b.charCodeAt(i+1)&255)*256+(b.charCodeAt(i+2)&255)*65536+(b.charCodeAt(i+3)&255)*16777216;}
 function check(file,level){
  var b=read(file),offset=128,fmt=b.substring(84,88);
  if(b.length<128||b.substring(0,4)!=='DDS '||u32(b,4)!==124)throw Error('Invalid DDS export');
  if(fmt==='DX10'){
   if(b.length<148||u32(b,132)!==3||u32(b,136)!==0||u32(b,140)!==1)throw Error('Unsupported DX10 texture');
   var map={71:'DXT1',72:'DXT1',74:'DXT3',75:'DXT3',77:'DXT5',78:'DXT5'};
   fmt=map[u32(b,128)];offset=148;
  }
  var block=job.fourcc==='DXT1'?8:16;
  var size=Math.max(1,Math.ceil(level.width/4))*Math.max(1,Math.ceil(level.height/4))*block;
  if(fmt!==job.fourcc||u32(b,16)!==level.width||u32(b,12)!==level.height||u32(b,28)>1||b.length!==offset+size)
   throw Error('DDS interface did not export the requested single '+job.fourcc+' mip');
 }
 function save(doc,file,kind){
  rgb(doc);var opts=new ActionDescriptor(),save=new ActionDescriptor(),type;
  if(kind==='legacy'){
   opts.putInteger(c('txfm'),{DXT1:0,DXT3:2,DXT5:3}[job.fourcc]);
   opts.putInteger(c('tmty'),0);opts.putInteger(c('mmty'),32);
   var flags=['sflp','nmcv','shfi','dthc','dth0','alpb','prem','bina','fdcl','fdaf'];
   for(var i=0;i<flags.length;i++)opts.putBoolean(c(flags[i]),false);
   type='NVIDIA D3D/DDS';
  }else{
   // Exporter format indices: BC1 RGB=9, BC2=7, BC3 RGBA=6.
   // Index 5 is BC3n and swizzles RGB/alpha; never use it for color maps.
   opts.putInteger(c('sFoI'),{DXT1:9,DXT3:7,DXT5:6}[job.fourcc]);
   opts.putInteger(c('sASC'),0);
   opts.putEnumerated(c('sTxT'),c('enTT'),c('tx2D'));
   opts.putBoolean(c('mipF'),false);
   opts.putEnumerated(c('iOOM'),c('eIOM'),c('eICo'));
   var off=['iOBS','iOWr','iOAZ','iOBA','iOSu','iOBD','iOPA','iO10','iOFV'];
   for(var j=0;j<off.length;j++)opts.putBoolean(c(off[j]),false);
   var channels=['r','g','b','a'];
   for(var k=0;k<channels.length;k++){
    opts.putDouble(c('iOS'+channels[k]),1);
    opts.putDouble(c('iBi'+channels[k]),0);
    opts.putDouble(c('iOB'+channels[k]),channels[k]==='a'?1:0);
   }
   opts.putInteger(c('iOCQ'),0);opts.putInteger(c('iOBT'),127);
   opts.putString(c('fxSt'),'0 ');opts.putInteger(c('sirV'),1);
   type='NVIDIA DDS - NVIDIA Texture Tools Exporter';
  }
  save.putObject(c('As  '),stringIDToTypeID(type),opts);
  save.putPath(c('In  '),new File(file));save.putBoolean(c('Cpy '),true);
  executeAction(c('save'),save,DialogModes.NO);
 }
 function encode(doc,level){
  var choices=adapter?[adapter]:(job.ddsInterface?[job.ddsInterface]:['legacy','exporter']),errors=[];
  for(var i=0;i<choices.length;i++){
   if(choices[i]!=='legacy'&&choices[i]!=='exporter')throw Error('Unknown DDS interface');
   try{save(doc,level.encoded,choices[i]);check(level.encoded,level);adapter=choices[i];return;}
   catch(e){errors.push(choices[i]+': '+e);var f=new File(level.encoded);if(f.exists)f.remove();}
  }
  throw Error('No usable Photoshop DDS interface. '+errors.join(' | '));
 }
 function resampling(source,level){
  var automatic;try{automatic=ResampleMethod.BICUBICAUTOMATIC;}catch(e){}
  if(automatic!==undefined)return automatic;
  // CS3 predates Automatic. Use its explicit reduction/enlargement filters.
  var w=source.width.as('px'),h=source.height.as('px');
  if(level.width<=w&&level.height<=h)return ResampleMethod.BICUBICSHARPER;
  if(level.width>=w&&level.height>=h)return ResampleMethod.BICUBICSMOOTHER;
  return ResampleMethod.BICUBIC;
 }
 try{
  if(job.expectedMajor&&parseInt(app.version,10)!==job.expectedMajor)throw Error('Photoshop version mismatch: '+app.version);
  app.displayDialogs=DialogModes.NO;app.preferences.rulerUnits=Units.PIXELS;
  var source=own(app.open(new File(job.tga)));
  if(source.width.as('px')!==job.sourceWidth||source.height.as('px')!==job.sourceHeight)throw Error('Source TGA dimensions changed');
  if(source.mode!==DocumentMode.RGB)source.changeMode(ChangeMode.RGB);
  if(source.bitsPerChannel!==BitsPerChannelType.EIGHT)source.bitsPerChannel=BitsPerChannelType.EIGHT;
  source.flatten();
  if(job.fourcc!=='DXT1'&&source.channels.length<4)throw Error('Source alpha channel missing in Photoshop');
  for(var n=0;n<job.levels.length;n++){
   var level=job.levels[n];app.activeDocument=source;
   var doc=own(source.duplicate('Conquer refined MIP'+level.index));
   var method=resampling(source,level);
   if(doc.width.as('px')!==level.width||doc.height.as('px')!==level.height)
    doc.resizeImage(UnitValue(level.width,'px'),UnitValue(level.height,'px'),null,method);
   methods.push('mip'+level.index+'='+method.toString());
   rgb(doc);var hp=doc.activeLayer.duplicate();hp.visible=true;
   hp.name='High Pass '+job.radius+'px / Overlay 100%';hp.applyHighPass(job.radius);
   hp.blendMode=BlendMode.OVERLAY;hp.opacity=job.opacity;hp.fillOpacity=job.fill;
   doc.flatten();rgb(doc);
   var proof=new TargaSaveOptions();proof.alphaChannels=true;proof.rleCompression=false;
   proof.resolution=doc.channels.length>3?TargaBitsPerPixels.THIRTYTWO:TargaBitsPerPixels.TWENTYFOUR;
   doc.saveAs(new File(level.proof),proof,true,Extension.LOWERCASE);
   encode(doc,level);
   doc.close(SaveOptions.DONOTSAVECHANGES);opened.pop();
  }
  return 'PHOTOSHOP_REFINE_OK|'+adapter+'|'+app.version+'|'+methods.join(';');
 }catch(error){return 'ERROR '+error.toString();}
 finally{
  for(var i=opened.length-1;i>=0;i--)try{opened[i].close(SaveOptions.DONOTSAVECHANGES);}catch(e){}
  app.displayDialogs=dialogs;app.preferences.rulerUnits=units;
  if(original)try{app.activeDocument=original;}catch(e){}
 }
})(__JOB__);
'@
$script=$template.Replace('__JOB__',$jobText)
# Coordinate with older installed releases while an upgrade is in progress.
$mutex=New-Object System.Threading.Mutex($false,'Local\ConquerPhotoshopMIP1')
if(-not $mutex.WaitOne(0)){ $mutex.Dispose(); throw 'Photoshop refinement already running' }
try {
    $app=New-Object -ComObject $ProgId
    $result=$app.DoJavaScript($script)
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
if($result -notlike 'PHOTOSHOP_REFINE_OK|*'){throw $result}
$result
