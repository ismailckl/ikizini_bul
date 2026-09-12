# İkizini Bul - Play Store Yayın Kontrolü

## Hazır olanlar

- Uygulama kimliği: `com.ismailckl.ikizinibul`
- Sürüm: `1.0.0+1`
- Hedef Android sürümü: API 36
- Play Store simgesi: `play_store_icon.png` (512x512)
- Tanıtım görseli: `feature_graphic_1024x500.png`
- Türkçe mağaza açıklaması: `play_store_listing_tr.md`
- Türkçe gizlilik politikası: `privacy_policy_tr.md`
- İmzalı Android App Bundle üretimi yapılandırıldı

## Yayından önce

1. `android/app/upload-keystore.jks` ve `android/key.properties` dosyalarını güvenli, ikinci bir konuma yedekle. Bu dosyalar GitHub'a gönderilmez.
2. Gizlilik politikasını herkese açık bir web adresinde yayınla ve bu adresi Play Console'a ekle.
3. Telefondan en az iki dikey oyun ekran görüntüsü al.
4. Play Console'da uygulamayı "Oyun > Eğitici" kategorisinde oluştur.
5. Veri güvenliği formunda uygulamanın veri toplamadığını belirt.
6. Çocukları hedef kitleye dahil edeceksen Aile Politikası sorularını doğru şekilde tamamla.
7. İlk sürümü önce dahili test kanalına yükle ve gerçek cihazda kontrol et.

## Sonraki sürümler

Her Play Store güncellemesinde `pubspec.yaml` içindeki `+1` yapı numarasını artır. Örneğin ikinci yükleme `1.0.1+2` olabilir.
