// Deterministic extraction of the official gold T; no new brand or AI rendering.
const path=require('path'),fs=require('fs'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),out=path.join(root,'assets/branding');
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const {data,info}=await sharp(path.join(root,'assets/images/app_icon.png')).extract({left:365,top:390,width:560,height:580}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(let i=0;i<data.length;i+=4){const r=data[i],g=data[i+1],b=data[i+2];data[i+3]=(r>40&&r>b*1.4&&g>b*1.15)?255:0;}
 // Keep only the connected T; discard fragments of the surrounding gold ring.
 const labels=new Int32Array(info.width*info.height),queue=new Int32Array(labels.length);
 let label=0,best=0,largest=0;
 for(let p=0;p<labels.length;p++){if(labels[p]||!data[p*4+3])continue;label++;let head=0,tail=1;queue[0]=p;labels[p]=label;while(head<tail){const q=queue[head++],x=q%info.width,y=Math.floor(q/info.width);for(const n of [x>0?q-1:-1,x+1<info.width?q+1:-1,y>0?q-info.width:-1,y+1<info.height?q+info.width:-1]){if(n>=0&&!labels[n]&&data[n*4+3]){labels[n]=label;queue[tail++]=n;}}}if(tail>largest){largest=tail;best=label;}}
 for(let p=0;p<labels.length;p++)if(labels[p]!==best)data[p*4+3]=0;
 const symbol=await sharp(data,{raw:info}).resize({width:188,height:188,fit:'inside'}).png().toBuffer();
 const meta=await sharp(symbol).metadata();
 const foreground=await sharp({create:{width:432,height:432,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:symbol,left:Math.floor((432-meta.width)/2),top:Math.floor((432-meta.height)/2)}]).png().toBuffer();
 await sharp(foreground).toFile(path.join(out,'android-adaptive-foreground.png'));
 const rgba=await sharp(foreground).raw().toBuffer();for(let i=0;i<rgba.length;i+=4){rgba[i]=255;rgba[i+1]=255;rgba[i+2]=255;}
 await sharp(rgba,{raw:{width:432,height:432,channels:4}}).png().toFile(path.join(out,'android-adaptive-monochrome.png'));
 const legacySymbol=await sharp(symbol).resize({width:340,height:340,fit:'inside'}).toBuffer();const lm=await sharp(legacySymbol).metadata();
 await sharp({create:{width:512,height:512,channels:4,background:'#031226'}}).composite([{input:legacySymbol,left:Math.floor((512-lm.width)/2),top:Math.floor((512-lm.height)/2)}]).png().toFile(path.join(out,'android-launcher-legacy.png'));
 // Approximate masks for editorial inspection; not emulator screenshots.
 const bg=await sharp({create:{width:432,height:432,channels:4,background:'#031226'}}).composite([{input:foreground,left:0,top:0}]).png().toBuffer();
 const visible=await sharp(bg).extract({left:72,top:72,width:288,height:288}).toBuffer();
 const masks=[['circle','<circle cx="144" cy="144" r="144" fill="white"/>'],['rounded','<rect width="288" height="288" rx="64" fill="white"/>'],['squircle','<rect width="288" height="288" rx="110" fill="white"/>']];
 const previews=[];for(let i=0;i<masks.length;i++){const mask=Buffer.from(`<svg width="288" height="288">${masks[i][1]}</svg>`);const image=await sharp(visible).composite([{input:mask,blend:'dest-in'}]).png().toBuffer();previews.push({input:image,left:20+i*308,top:20});}
 const preview=path.join(root,'build/icon-preview');fs.mkdirSync(preview,{recursive:true});
 await sharp({create:{width:944,height:328,channels:4,background:'#cad4df'}}).composite(previews).png().toFile(path.join(preview,'android-icon-masks.png'));
 console.log('Wrote official-derived foreground, monochrome and legacy icons; mask preview in build/icon-preview.');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
