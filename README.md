# Ikizini Bul

Ikizini Bul, mobil ve akilli tahta icin tasarlanan rekabetci bir hafiza
eslestirme oyunudur. Uygulama mobil solo modda acilir; isteyen kullanici ust
mod seciciden akilli tahta split-screen yaris moduna gecebilir. Skorlar ve
sinif listeleri cihaz icinde ucretsiz olarak saklanir.

## Ilk Mimari

- `lib/game`: UI'dan ayrilmis oyun motoru, kart durumlari ve split-screen yaris
  controller'i.
- `lib/leaderboards`: Yerel skor ve sinif listeleri icin ortak repository
  arayuzleri.
- `lib/leaderboards/local`: Cihaz ici ozel liste mantiginin store tabanli
  repository'si, JSON codec'i, memory store'u, ucretsiz shared_preferences
  store'u, olusturulabilir sinif listeleri, sinif listesi controller'i ve solo
  liste controller'i.
- `lib/team`: Bayrak yarisi takim sirasi, takim setup JSON codec'i ve ucretsiz
  shared_preferences takim store'u.

## Mevcut Mobil Solo Akisi

1. Uygulama mobil solo modda acilir.
2. Tek oyun oturumu zamana karsi calisir.
3. Oyuncu kart setini Harfler, Sayilar veya Sekiller arasindan secebilir.
4. Oyun bitince skor solo yerel listeye tek kez kaydedilir.
5. Solo paneli cihazdaki en iyi yerel skorlari gosterir.

## Mevcut Akilli Tahta Akisi

1. Ogretmen ust bardan takim oyuncularini duzenleyebilir.
2. Ogretmen kart setini Harfler, Sayilar veya Sekiller arasindan secebilir.
3. Ogretmen yarisi baslatir.
4. Sol ve sag tahta birbirinden bagimsiz sure, hamle ve eslesme sayaci ile
   calisir.
5. Her takimda aktif ogrenci ekranda gorunur.
6. Dogru eslesmede sira bir sonraki takim arkadasina gecer.
7. Yanlis eslesmede ayni ogrenci devam eder; ust uste iki yanlista sira gecer.
8. Ilk bitiren taraf kazanan olur.
9. Kazananin skoru secili yerel sinif listesine tek kez kaydedilir.
10. Turnuva seridi secili listeyi, ilk 3 skoru ve son kayit durumunu gosterir.
11. Ogretmen yeni sinif/turnuva listesi olusturabilir veya secili listeyi
    silebilir.
12. Takim oyunculari ve sinif listeleri cihaz icinde ucretsiz olarak saklanir.

## Sonraki Adimlar

1. Mobil cihazda farkli ekran boyutlariyla son UI testlerini yap.
2. Akilli tahta cihazinda coklu dokunmatik ve buyuk ekran testleri yap.
3. Yayina hazir imzali Android build ayarlarini tamamla.

## Komutlar

Flutter batch komutu bu makinede yavas acilirsa dogrudan tools snapshot'i
kullanilabilir:

```powershell
& 'C:\fluttersrc\flutter\bin\cache\dart-sdk\bin\dart.exe' 'C:\fluttersrc\flutter\bin\cache\flutter_tools.snapshot' test
```
