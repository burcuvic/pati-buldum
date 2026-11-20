const fs=require('fs'),path=require('path');
const sharp=require(require.resolve('sharp',{paths:[process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES]}));
(async()=>{
 let icon=fs.readFileSync('resources/icon.svg','utf8').replace('<svg viewBox="0 0 64 64"','<svg width="64" height="64" viewBox="0 0 64 64"');fs.writeFileSync('resources/icon.svg',icon);
 await sharp(Buffer.from(icon)).png().toFile('resources/icon.png');
 const svg=Buffer.from(icon);
 await sharp(svg).resize(1024,1024).png().toFile('ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png');
 function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)])}
 for(const f of files('android/app/src/main/res').filter(f=>/ic_launcher.*\.png$/.test(f))){const m=await sharp(f).metadata();await sharp(svg).resize(m.width,m.height).png().toFile(f+'.tmp');fs.renameSync(f+'.tmp',f)}
 const splash=Buffer.from('<svg width="2732" height="2732" xmlns="http://www.w3.org/2000/svg"><rect width="2732" height="2732" fill="#5b2ca8"/><image href="data:image/svg+xml;base64,'+svg.toString('base64')+'" x="960" y="960" width="812" height="812"/></svg>');
 const splashFiles=[...files('android/app/src/main/res'),...files('ios/App/App/Assets.xcassets/Splash.imageset')].filter(f=>/splash.*\.png$/.test(f));
 for(const f of splashFiles){const m=await sharp(f).metadata();await sharp(splash).resize(m.width,m.height,{fit:'cover'}).png().toFile(f+'.tmp');fs.renameSync(f+'.tmp',f)}
 console.log('PAWLO native icons and splash assets generated.');
})().catch(e=>{console.error(e);process.exit(1)});
