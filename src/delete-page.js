// Web hesap silme sayfası: uygulamadaki ile aynı güvenli akışı kullanır.
// Şifre ile giriş yapılır, ardından delete-account fonksiyonu şifreyi sunucuda tekrar doğrular.
import { createClient } from '@supabase/supabase-js';
import { supabaseUrl, publishableKey } from './config.js';

const client = createClient(supabaseUrl, publishableKey, { auth: { persistSession: false, autoRefreshToken: false } });
const form = document.getElementById('deleteForm');
const message = document.getElementById('message');
const button = document.getElementById('submitButton');

function show(text, ok = false) {
  message.textContent = text;
  message.className = ok ? 'ok' : 'error';
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const phrase = document.getElementById('phrase').value.trim().toLocaleUpperCase('tr-TR');
  if (!email || !password) { show('E-posta adresini ve şifreni yaz.'); return; }
  if (phrase !== 'SİL') { show('Onaylamak için büyük harflerle SİL yaz.'); return; }

  button.disabled = true;
  show('Kontrol ediliyor…', true);
  try {
    const { error: loginError } = await client.auth.signInWithPassword({ email, password });
    if (loginError) { show('E-posta veya şifre hatalı.'); button.disabled = false; return; }
    const { error } = await client.functions.invoke('delete-account', { body: { password, confirmation: 'SİL' } });
    if (error) throw error;
    await client.auth.signOut().catch(() => {});
    form.reset();
    document.getElementById('formCard').innerHTML = '<h2 style="margin-top:0">Hesabın silindi</h2><p class="ok">Hesabın ve sana ait tüm veriler kalıcı olarak silindi. PAWLO’yu kullandığın için teşekkürler.</p>';
  } catch {
    await client.auth.signOut().catch(() => {});
    show('Hesap şu an silinemedi. Bağlantını kontrol edip tekrar dene ya da destek adresine yaz.');
    button.disabled = false;
  }
});
