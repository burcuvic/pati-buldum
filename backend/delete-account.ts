import { createClient } from 'npm:@supabase/supabase-js@2.119.0';
const allowed=new Set(['https://buldum-app.vercel.app','https://localhost','http://localhost','capacitor://localhost']);
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get('origin')||'';
 const headers={'Content-Type':'application/json','Access-Control-Allow-Origin':allowed.has(origin)?origin:'https://buldum-app.vercel.app','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Vary':'Origin'};
 const respond=(status:number,message:string)=>new Response(JSON.stringify({message}),{status,headers});
 if(origin&&!allowed.has(origin))return respond(403,'Origin rejected');
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return respond(405,'Method not allowed');
 const token=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');if(!token)return respond(401,'Authentication required');
 const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
 const verifier=createClient(url,anon,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data:{user},error}=await verifier.auth.getUser(token);if(error||!user?.email)return respond(401,'Session invalid');
 try{
  const body=await req.json();if(body.confirmation!=='SİL'||typeof body.password!=='string')return respond(400,'Confirmation required');
  const reauth=await verifier.auth.signInWithPassword({email:user.email,password:body.password});if(reauth.error||reauth.data.user.id!==user.id)return respond(403,'Verification failed');
  const admin=createClient(url,secret,{auth:{persistSession:false,autoRefreshToken:false}});
  for(const bucket of ['pet-photos','sighting-photos']){
   for(let batch=0;batch<200;batch++){
    const {data:files,error:listingError}=await admin.storage.from(bucket).list(user.id,{limit:100});if(listingError)throw listingError;if(!files?.length)break;
    const paths=files.filter(f=>f.id).map(f=>user.id+'/'+f.name);if(!paths.length)throw Error('Unexpected object structure');
    const {error:removeError}=await admin.storage.from(bucket).remove(paths);if(removeError)throw removeError;
    if(batch===199)throw Error('Cleanup incomplete');
   }
  }
  const deleted=await admin.auth.admin.deleteUser(user.id);if(deleted.error)throw deleted.error;
  return respond(200,'Account and associated data deleted');
 }catch{return respond(500,'Deletion failed; retry later')}
});
