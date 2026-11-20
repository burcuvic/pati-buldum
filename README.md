# PAWLO · Mobil beta kaynak projesi

Sarı/mor arayüz, gerçek OpenStreetMap haritası, Supabase üyelik/veritabanı/depolama ve Capacitor Android/iOS projeleri.

## Bu aşamada tamamlananlar

- `burcuvic's Org` içinde ayrı `pawlo` projesi: `audwschlqoatedhxmdec`, Frankfurt.
- Kalıcı ilan, fotoğraf, görülme noktası, profil görünürlük tercihi, rütbe sayacı ve uygulama içi sahip bildirimleri.
- E-posta/şifre ile üyelik ve giriş; doğrulanmamış e-postayı doğrulanmış kabul eden bir kestirme yoktur.
- Özel profil bilgilerine yalnızca hesabın sahibi erişir. Topluluğa yalnızca izin verilen ad veya “Gizli kahraman” gösterilir.
- İlan fotoğrafları yayımlama işleminde açık depolamaya yüklenir. Görülme fotoğrafları özel depolamada kalır; bildiren kişi ve ilgili ilan sahibi erişebilir.
- İki fotoğrafla ilan açma, haritadan/GPS ile konum seçme, kayıp ilanını yuvasına döndü olarak kapatma.
- İçerik bildirme ve kullanıcı gizleme; hesap ve dosyaları silme Edge Function'ı.
- Cihaz üzerinde MobileNet v2 genel görsel özellikleriyle benzer ilan sıralama. Bu bir hayvan kimlik modeli değildir. Yüzde eşleşme olasılığı üretilmez; kullanıcı gördüğü köpeği seçer.
- Android ve iOS yerel kamera/konum eklentileri, izin açıklamaları, PAWLO uygulama ikonu ve açılış görselleri.

## Doğrulamalar

- JavaScript sözdizimi ve üretim derlemesi geçti; Capacitor iki platforma senkronize edildi.
- `backend/check-access.sql` canlı veritabanında çalıştırıldı ve tüm değişiklikler geri alındı. Profil gizliliği, ad maskeleme, sunucu sayacı, sahip bildirimi, kendine madalya kazandırmayı engelleme, anonim yetkiler ve kullanıcı gizleme kontrolleri geçti.
- Güvenlik danışmanı: açık bulgu yok.
- Açık ilan ve topluluk REST uçları 200; anonim profil ve bildirim erişimleri 401; kimliksiz hesap silme isteği 401 döndü.
- MobileNet v2 gerçek ağırlıklarıyla 1280 boyutlu sonlu özellik vektörü üretimi test edildi. Aynı girişin kosinüs benzerliği 1.000000 çıktı. Bu test gerçek hayvan tanıma başarımı ölçmez.

## Yayın öncesi açık kalanlar

1. Supabase panelinde Authentication → URL Configuration: Site URL `https://buldum-app.vercel.app`; izin verilen yönlendirme `https://buldum-app.vercel.app/`.
2. Authentication → Email/SMTP: kullanıcılara doğrulama e-postası gönderebilen bir gönderici yapılandırılmalı. Varsayılan e-posta servisi genel kullanıma uygun teslimat garantisi vermez ve alıcı kısıtları olabilir. Panel bu oturumda giriş ekranında kaldığı için bu ayarlar değiştirilmedi.
3. Gerçek e-posta doğrulama → giriş → iki fotoğrafla ilan → ikinci hesapla görülme → sahip bildirimi → hesap silme akışı iki test hesabıyla tamamlanmalı. Şu ana kadar gerçek kişilere test e-postası gönderilmedi.
4. Gizlilik metnine veri sorumlusu iletişim adresi ve içerik bildirimlerini inceleme/destek iletişim bilgisi eklenmeli. Mevcut sayfa uygulamanın veri kullanımını açıklar; hukuk incelemesi yapıldığı iddia edilmez.
5. Native Android ve iOS uygulamaları fiziksel cihazlarda denenmeli. Android test APK’sı derlendi ve imzası doğrulandı. Fiziksel cihaz testi, Play Store için imzalı AAB ve iOS için Xcode derlemesi henüz yapılmadı.
6. Google Play Console ve Apple Developer hesapları kullanıcı adına açılmalı; sözleşmeler, kimlik doğrulama ve ödemeler kullanıcı tarafından tamamlanmalı. Mağaza incelemesine başvuru yapılmadı; kabul garantisi yoktur.
7. Google ve Apple veri güvenliği/gizlilik formları gerçek veri akışına göre doldurulmalı; ilgili test şartları ve güncel hedef SDK gereklilikleri yayın tarihinde tekrar kontrol edilmeli.

Oturum tokenları bu beta sürümünde kalıcı diske yazılmaz (`persistSession:false`); uygulama yeniden açılınca tekrar giriş gerekir. Veritabanı ve dosyalar ise kalıcıdır. Arka plan push bildirimi henüz yoktur; bildirimler uygulama içindedir. Varsayılan liste sorguları 250 ilan/2000 görülme/250 kahraman ile sınırlıdır; daha büyük açılımdan önce sunucu sayfalaması, bölgesel sorgu ve kötüye kullanım sınırları geliştirilmelidir.

## Yerel çalışma

Node.js 22 veya üstü:

```sh
npm ci
npm run check
npm run build
npx cap sync
```

`dist/` statik web dağıtımının tamamıdır. Android Studio'da `android/`, Xcode'da `ios/App/App.xcodeproj` açılır. Paket kimliği taslağı `app.pawlo.mobile`; mağaza kayıtları oluşturulmadan önce kimlik kararı kesinleştirilmelidir.

`src/config.js` yalnızca istemci için yayımlanabilir Supabase anahtarı içerir; servis rolü anahtarı içermez. Hesap silme fonksiyonu kendi JWT/kullanıcı doğrulamasını ve şifreyle yeniden doğrulamayı yapar. Fonksiyon ortamındaki servis rolü anahtarı istemciye gönderilmez.

`backend/schema.sql` ilk kurulumun açıklamalı kaynağıdır; mevcut projeye yeniden körlemesine çalıştırılmaz. Veritabanı zaten kurulmuştur.

## Dağıtım durumu

Canlı alan adı mevcut tasarım demosunda bırakıldı. Gerçek veritabanına bağlı sürüm Vercel'de korumalı test dağıtımı olarak hazırlanmıştır. Üyelik/e-posta ve iki hesapla uçtan uca doğrulama tamamlanmadan genel kullanıma geçirilmemelidir.

Bu arşiv kaynak kodudur. Android test paketi ayrıca pawlo-android-beta.apk olarak verilir; mağazaya gönderilmiş sürüm yoktur.
