import { build } from 'esbuild';import fs from 'node:fs/promises';
await fs.rm('dist',{recursive:true,force:true});await fs.mkdir('dist/assets',{recursive:true});
await build({entryPoints:['src/app.js'],bundle:true,splitting:true,format:'esm',target:['es2022'],minify:true,outdir:'dist/assets',entryNames:'app',chunkNames:'chunk-[hash]',legalComments:'linked'});
await build({entryPoints:['src/delete-page.js'],bundle:true,format:'esm',target:['es2022'],minify:true,outfile:'dist/assets/delete-page.js',legalComments:'linked'});
for(const page of ['gizlilik.html','hesap-silme.html'])await fs.copyFile('src/pages/'+page,'dist/'+page);await fs.copyFile('src/pages/pages.css','dist/assets/pages.css');
await fs.copyFile('src/index.html','dist/index.html');await fs.copyFile('src/style.css','dist/assets/style.css');await fs.copyFile('src/leaflet.js','dist/assets/leaflet.js');
console.log('PAWLO built. Model weights are loaded on demand, after a photo search.');
