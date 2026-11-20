# PAWLO · Değişiklikler (20 Kasım 2026)

Önizleme sürümü. Canlı site ve veritabanı bu paketle değiştirilmedi.

## 1. paket · Ana ekran ve takip
- Yeni kompakt ana ekran: küçük logo, üstte büyük BULDUM kartı, "Dostumu kaybettim", "Bir yerde gördüm", "Haritada kayıp ilanlar".
- Büyük yazı ayarında ve küçük ekranlarda taşma düzeltmeleri; yazılar rem birimine çevrildi.
- BULDUM: fotoğraf çek veya galeriden seç (web ve telefon).
- Oturum hatırlanıyor (persistSession). Açılışta kullanıcı ana ekranda kalıyor.
- İlan detayı: "Son görülme" özeti, Tümü / Son 7 gün / Son 24 saat filtresi, numaralı noktalar, noktalar arası mesafe.
- "Son noktayı Google Haritalar'da aç" bağlantısı (ücretsiz, anahtar gerekmez).

## 2. paket · Gizlilik ve hesap silme
- /gizlilik.html: Gizlilik Politikası ve KVKK Aydınlatma Metni (taslak; sarı alanlar doldurulmalı, hukukçu kontrolü önerilir).
- /hesap-silme.html: Google Play için web'den hesap silme (mevcut delete-account fonksiyonunu kullanır).
- Uygulama içi "Gizlilik ve veriler" ekranına bu sayfaların bağlantıları.

## 3. paket · Kedi desteği
- İlan formunda tür seçimi (Köpek / Kedi / Diğer); "Cinsi" isteğe bağlı.
- İlan listesinde ve BULDUM sonuçlarında tür filtresi.
- Köpeğe özel metinler genelleştirildi.
- Veritabanı eki: backend/migrations/2026-11-20_tur_alani.sql (HENÜZ ÇALIŞTIRILMADI). Çalıştırılmasa da ilan verme bozulmaz.

## Diğer düzeltmeler
- İlan yayınlandıktan sonra formda takılı kalma sorunu.
- İlan formundaki dev kamera ikonları.

## Yayın öncesi açık işler
- Supabase e-posta/SMTP ve yönlendirme ayarları.
- Gizlilik metnindeki veri sorumlusu ve destek e-postası.
- Tür alanı SQL'inin çalıştırılması.
- İki gerçek hesapla uçtan uca test, fiziksel telefon testi.
- Google Play hesabı (tek seferlik 25 $), 12 kişi / 14 gün kapalı test, imzalı AAB.
- Harita karo sağlayıcısı (OpenStreetMap ücretsiz sunucusu mağaza uygulaması için uygun değil).
