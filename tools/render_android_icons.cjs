// Preserve the FULL official artwork: navy rounded square, gold ring, T and sparkle.
const path=require('path'),fs=require('fs'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),out=path.join(root,'assets/branding');
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const source=path.join(root,'assets/images/app_icon.png');
 const roundedMask=Buffer.from('<svg width="208" height="208"><rect width="208" height="208" rx="42" fill="white"/></svg>');
 // Fit the complete rounded-square badge in the safe area; no content crop.
 const symbol=await sharp(source).resize(208,208).ensureAlpha().composite([{input:roundedMask,blend:'dest-in'}]).png().toBuffer();
 const meta=await sharp(symbol).metadata();
 const foreground=await sharp({create:{width:432,height:432,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:symbol,left:Math.floor((432-meta.width)/2),top:Math.floor((432-meta.height)/2)}]).png().toBuffer();
 await sharp(foreground).toFile(path.join(out,'android-adaptive-foreground.png'));
 // Themed icon keeps the full gold contours (ring, T, reflection and frame),
 // rather than the opaque square or an isolated T. Android chooses themed colors.
 const rgba=await sharp(foreground).raw().toBuffer();for(let i=0;i<rgba.length;i+=4){const r=rgba[i],g=rgba[i+1],b=rgba[i+2];const gold=r>55&&g>40&&r>b*1.25&&g>b*1.1;rgba[i+3]=gold?rgba[i+3]:0;rgba[i]=255;rgba[i+1]=255;rgba[i+2]=255;}
 await sharp(rgba,{raw:{width:432,height:432,channels:4}}).png().toFile(path.join(out,'android-adaptive-monochrome.png'));
 await sharp(source).resize(512,512).ensureAlpha().png().toFile(path.join(out,'android-launcher-legacy.png'));
 // Approximate masks for editorial inspection; not emulator screenshots.
 const bg=await sharp({create:{width:432,height:432,channels:4,background:'#031226'}}).composite([{input:foreground,left:0,top:0}]).png().toBuffer();
 const visible=await sharp(bg).extract({left:72,top:72,width:288,height:288}).toBuffer();
 const masks=[['circle','<circle cx="144" cy="144" r="144" fill="white"/>'],['rounded','<rect width="288" height="288" rx="64" fill="white"/>'],['squircle','<rect width="288" height="288" rx="110" fill="white"/>']];
 const previews=[];for(let i=0;i<masks.length;i++){const mask=Buffer.from(`<svg width="288" height="288">${masks[i][1]}</svg>`);const image=await sharp(visible).composite([{input:mask,blend:'dest-in'}]).png().toBuffer();previews.push({input:image,left:20+i*308,top:20});}
 const preview=path.join(root,'build/icon-preview');fs.mkdirSync(preview,{recursive:true});
 await sharp({create:{width:944,height:328,channels:4,background:'#cad4df'}}).composite(previews).png().toFile(path.join(preview,'android-icon-official-masks.png'));
 console.log('Wrote FULL official foreground, ring/T monochrome and full legacy icon; mask preview in build/icon-preview.');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
