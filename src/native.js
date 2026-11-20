import { Capacitor } from '@capacitor/core';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { Geolocation } from '@capacitor/geolocation';
export const isNative=()=>Capacitor.isNativePlatform();
export async function nativePhoto(){
 const photo=await Camera.getPhoto({source:CameraSource.Prompt,promptLabelHeader:'Fotoğraf',promptLabelPhoto:'Galeriden seç',promptLabelPicture:'Fotoğraf çek',promptLabelCancel:'Vazgeç',resultType:CameraResultType.Uri,quality:90,correctOrientation:true,width:1600});
 const response=await fetch(photo.webPath);const blob=await response.blob();
 return new File([blob],'pawlo-camera.jpg',{type:blob.type||'image/jpeg'});
}
export const nativePosition=()=>Geolocation.getCurrentPosition({enableHighAccuracy:true,timeout:10000,maximumAge:0});
