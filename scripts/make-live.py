from pathlib import Path
import re
root=Path(__file__).resolve().parent.parent
p=root/'src/app.js';s=p.read_text()
imports="""import {client,ensureProfile,loadPublic,publicPhoto,postPet,postSighting,updatePrivacy,myNotifications,readNotification,sightingPhoto,reportContent,blockUser,resolvePet} from './backend.js';
import {isNative,nativePhoto,nativePosition} from './native.js';
"""
s=imports+s
def replace_line(prefix,replacement):
 global s
 s,n=re.subn('^'+re.escape(prefix)+'.*$',lambda _:replacement,s,flags=re.M)
 assert n==1,(prefix,n)
replace_line('const dogs=', 'let dogs=[];')
replace_line('const heroes=', 'const heroes=[];')
replace_line('const reports=', 'const reports=[];')
replace_line('dogs.forEach(', '')
s=s.replace("postRedirect:false,geoMessage:''", "postRedirect:false,geoMessage:'',loaded:false,publishing:false,ranked:[],matchUnavailable:false")
new=(root/'src/live-functions.js.txt').read_text()
names=re.findall(r'^(?:async )?function (\w+)\(',new,re.M)
for name in names:
 pattern=r'^(?:async )?function '+name+r'\(.*$'
 if re.search(pattern,s,re.M):s=re.sub(pattern,'',s,flags=re.M)
s=s.replace("function renderScreen(){", new+'\nfunction renderScreen(){')
replace_line("byId('cameraFile').onchange=", "byId('cameraFile').onchange=e=>{const file=e.target.files?.[0];if(file)processPhoto(file)};")
# Use native GPS inside the installed app; browser permission behavior is unchanged.
s=s.replace("navigator.geolocation.getCurrentPosition(pos=>", "getDevicePosition(pos=>")
s=s.replace("function geoPoint(){", "function getDevicePosition(ok,fail,options){if(isNative())nativePosition().then(ok).catch(fail);else navigator.geolocation.getCurrentPosition(ok,fail,options)}\nfunction geoPoint(){")
s=s.replace("if(!navigator.geolocation){", "if(!navigator.geolocation&&!isNative()){")
s=s.replace("function dogCards(){return dogs.map", "function dogCards(){return dogs.filter(d=>d.status==='lost').map")
# Empty state never fabricates sample listings.
s=s.replace("+'</p>'+dogCards();break;", "+'</p>'+dogCards()+(!dogs.some(d=>d.status==='lost')?'<div class=\"card\"><p class=\"lead\">'+(session.loaded?'Henüz kayıp ilanı yok. Menüden ilk ilanı verebilirsin.':'İlanlar yükleniyor…')+'</p></div>':'');break;")
s=s.replace("<span class=\"demo-pill\">ÖRNEK DEMO VERİLERİ</span>","<span class=\"demo-pill\">PAWLO TOPLULUĞU</span>")
s=s.replace("Pamuk ve Boncuk örnek ilanlardır. Yeni ilanlar seçtiğin gerçek konumda görünür.","Aktif kayıp ilanlarının son görülme noktaları gösterilir.")
s=s.replace("dogs.map(d=>({...d.route.at(-1),dogId:d.id,dogLabel:d.label}))", "dogs.filter(d=>d.status==='lost').map(d=>({...d.route.at(-1),dogId:d.id,dogLabel:d.label}))")
s=s.replace("case'account':renderAccount();break;", "case'account':renderAccount();break;case'login':renderSignup(true);break;case'candidates':renderCandidates();break;case'notifications':renderNotifications();break;case'privacy':renderPrivacy();break;case'deleteAccount':renderDeleteAccount();break;case'report':renderReport();break;case'findingLocation':view.innerHTML='<div class=\"center-screen\" role=\"status\"><div class=\"scan-ring\">'+pawLogo+'</div><h2>Konumun alınıyor…</h2><p>Gördüğün yeri belirliyoruz.</p></div>';break;case'publishing':view.innerHTML='<div class=\"center-screen\" role=\"status\"><div class=\"scan-ring\">'+pawLogo+'</div><h2>Bildirim kaydediliyor…</h2><p>Fotoğraf ve konumun ilanın sahibine ulaştırılıyor.</p></div>';break;")
s=s.replace("<h2>Yapay zeka<br>eşleştiriyor…</h2>","<h2>Fotoğrafın<br>karşılaştırılıyor…</h2>")
s=s.replace("<span class=\"demo-pill\">DEMO EŞLEŞTİRME</span>","<p id=\"scanProgress\" class=\"muted\" role=\"status\">İlanlar hazırlanıyor…</p>")
s=s.replace("Bu fotoğraf için bir kayıp ilanı eşleşmesi bulamadık. Bir sonraki iz yeni bir umut olabilir.","Karşılaştırılabilecek aktif bir kayıp ilanı yok. Daha sonra yeniden deneyebilirsin.")
s=s.replace("<p class=\"muted\">Bu sonuç demo anahtarına göre oluşturulmuştur.</p>","")
s=s.replace("için görülme bildirimin demo yol haritasına eklendi.","için görülme bildirimin kaydedildi ve ilan sahibine uygulama içi bildirim oluşturuldu.")
s=s.replace("Seçtiğin konum bu demo oturumundaki görülme bildirimine eklenir.","Yayınladığında bu konum görülme haritasında görünür. Fotoğrafı yalnızca sen ve ilanın sahibi açabilir.")
# Remove the obsolete fake match screen entirely.
s=re.sub(r"case'match':\{.*?;break\}case'published'", "case'published'",s)
s=s.replace("'<br>Örnek bildirim'", "'<br>İlk kayıp konumu'")
# Ownership and content controls belong to the detail page.
s=s.replace(";mountMap('routeMap',d.route)}", ";view.innerHTML+='<div class=\"map-tools\">'+(d.ownerId===session.user?.id&&d.status==='lost'?'<button class=\"button accent\" data-action=\"resolve-pet\">Yuvasına döndü</button>':d.ownerId!==session.user?.id?'<button class=\"button secondary\" data-action=\"report-content\">İlanı bildir</button><button class=\"button secondary\" data-action=\"block-author\">Kullanıcıyı gizle</button>':'')+'</div>';mountMap('routeMap',d.route)}")
# Live actions are async; existing navigation stays synchronous.
s=s.replace("document.addEventListener('click',e=>", "document.addEventListener('click',async e=>")
s=s.replace("if(action==='logout'){session.user=null;", "if(action==='logout'){await client.auth.signOut();session.user=null;")
s=s.replace("notice('Çıkış yaptın.');return}", "await refreshRecords();notice('Çıkış yaptın.');return}")
actions="""if(action==='choose-match'){await chooseMatch(b.dataset.id);return}if(action==='delete-account'){navigate('deleteAccount');return}if(action==='report-content'){navigate('report');return}if(action==='block-author'){if(!session.user){navigate('login');return}const d=dogById(session.detailId);if(d&&confirm('Bu kullanıcının ilanlarını gizlemek istiyor musun?')){try{await blockUser(session.user,d.ownerId);await refreshRecords();navigate('lost');notice('Kullanıcı gizlendi.')}catch(error){notice(readableError(error))}}return}if(action==='resolve-pet'){if(confirm('Bu dostumuzun yuvasına döndüğünü onaylıyor musun?')){try{await resolvePet(session.detailId);await refreshRecords();navigate('account');notice('Ne güzel haber! İlanın arama listesinden kaldırıldı.')}catch(error){notice(readableError(error))}}return}if(action==='notification-detail'){try{await readNotification(b.dataset.id);session.detailId=b.dataset.pet;navigate('detail');if(b.dataset.photo){const url=await sightingPhoto(b.dataset.photo),container=document.createElement('div');container.className='card';const img=document.createElement('img');img.src=url;img.alt='Görülme bildirimi fotoğrafı';img.style.cssText='width:100%;border-radius:16px';container.append(img);view.prepend(container)}}catch(error){notice(readableError(error))}return}"""
s=s.replace("if(action==='capture'){",actions+"if(action==='capture'){")
s=s.replace("['home','signup','account','found','lost','post','map']", "['home','signup','login','account','found','lost','post','map','notifications','privacy']")
s=s.replace("navigate('home');\n})();", "navigate('home');\nrefreshRecords().catch(error=>notice('İlanlar yüklenemedi: '+readableError(error)));\nclient.auth.getSession().then(({data})=>{if(data.session)afterAuth(data.session.user).catch(error=>notice(readableError(error)))});\n})();")
p.write_text(s)
