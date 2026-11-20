import * as tf from '@tensorflow/tfjs';
import * as mobilenet from '@tensorflow-models/mobilenet';
let modelPromise;const vectorCache=new Map();
async function imageElement(src){const image=new Image();image.crossOrigin='anonymous';image.src=src;await image.decode();return image}
async function vector(src){if(vectorCache.has(src))return vectorCache.get(src);modelPromise??=mobilenet.load({version:2,alpha:1.0,modelUrl:'https://storage.googleapis.com/tfjs-models/savedmodel/mobilenet_v2_1.0_224/model.json',inputRange:[-1,1]});const model=await modelPromise,image=await imageElement(src);const features=model.infer(image,true);try{const values=Float32Array.from(await features.data());let norm=Math.sqrt(values.reduce((sum,v)=>sum+v*v,0));if(!norm)throw Error('Fotoğraf özellikleri okunamadı.');for(let i=0;i<values.length;i++)values[i]/=norm;vectorCache.set(src,values);return values}finally{features.dispose()}}
export async function rankPhotos(photo,dogs,onProgress=()=>{}){
 await tf.ready();const query=await vector(photo),ranked=[];let index=0;
 // This is generic visual similarity, never a calibrated identity probability.
 for(const dog of dogs){let best=-1;for(const source of [dog.front,dog.side]){if(!source)continue;try{const v=await vector(source);let score=0;for(let i=0;i<query.length;i++)score+=query[i]*v[i];best=Math.max(best,score)}catch{ /* one inaccessible listing photo must not stop the entire search */ }}if(best>=0)ranked.push({dog,similarity:best});onProgress(++index,dogs.length);await tf.nextFrame()}
 return ranked.sort((a,b)=>b.similarity-a.similarity).slice(0,5);
}
