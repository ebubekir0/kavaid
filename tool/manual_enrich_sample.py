import csv
import os

csv_path = r'c:\Users\kul\Desktop\kavaid1111\kelimeler_genisletilmis.csv'

# AI tarafından üretilen zenginleştirilmiş anlamlar (Örnek küme)
enrichment_data = {
    "ancak": "lakin, fakat, ama, sadece, yalnız, sırf, salt, oysa, ne var ki, hal böyleyken, mamafih, tek, bir tek, özgü, münhasır",
    "bahtiyar": "mutlu, mesut, şanslı, talihli, ongun, saadetli, sevinçli, kutlu, uğurlu, bahtı açık, huzurlu, hoşnut, memnun, ferah, neşeli",
    "baltalama": "engelleme, sabote etme, köstek olma, mani olma, durdurma, bozma, aksatma, sekteye uğratma, önleme, tıkanıklık çıkarma, zarar verme, çürütme, işi bozma, bloke etme",
    "bardak": "kadeh, kupa, maşrapa, su kabı, cam kap, billur, peyman, kâse, fincan, çamçak, su bardağı, çay bardağı, meşrubat bardağı, içecek kabı, kulplu bardak",
    "başhekim": "baştabip, ser-tabip, hastane yöneticisi, baş doktor, tıbbi direktör, kıdemli hekim, sorumlu doktor, hekimbaşı, başhekim yardımcısı, klinik şefi, idari hekim, hastane amiri",
    "bence": "bana göre, kanaatimce, fikrimce, zannımca, bana kalırsa, nezdinde, nazarımda, benim açımdan, düşünceme göre, şahsi fikrim, inanıyorum ki, görüyorum ki, tahminimce, bana sorarsan",
    "bulunuyor": "mevcut, var, yer alıyor, ikamet ediyor, duruyor, konumlanmış, mevcut durumda, hazırda, el altında, içeriyor, kapsıyor, bünyesinde barındırıyor, teşkil ediyor, hasıl oluyor",
    "Arapça": "Arap dili, Arabi, Lisan-ı Arabi, Kuran dili, Sami dili, Hicaz lehçesi, Fasih Arapça, Modern Standart Arapça, Arapça konuşma, Arapça yazısı, Orta Doğu dili",
    "Adana": "Adana ili, Çukurova bölgesi, güney ili, pamuk diyarı, Akdeniz şehri, Seyhan, Ceyhan, kebap şehri, sıcak memleket, tarım merkezi, sanayi kenti, güneyin incisi",
    "Anadolu": "Anatolia, Küçük Asya, Anadolu yarımadası, Türkiye toprakları, medeniyetler beşiği, doğu diyarı, Rumeli karşıtı, Asya tarafı, Türk yurdu, güneşin doğduğu yer, bereketli topraklar",
    "Bursa": "Yeşil Bursa, Osmanlı başkenti, Uludağ şehri, tekstil kenti, ipek şehri, tarih kenti, kaplıca merkezi, Marmara ili, güney Marmara, iskender şehri, şeftali diyarı",
    "Mahmud": "övülmüş, methedilmiş, beğenilmiş, sena edilmiş, takdir edilmiş, övgüye layık, Muhammed isminin kökü, seçkin, makbul, muteber, şerefli, ali",
    "Mustafa": "seçilmiş, seçkin, güzide, muhtar, el-Mustafa, temizlenmiş, arınmış, saf, pak, Hz. Peygamber'in ismi, seçilmiş kul, tercih edilmiş",
    "Türkçe": "Türk dili, Lisan-ı Türki, İstanbul Türkçesi, ana dil, resmi dil, Ural-Altay dili, Oğuz grubu, Türkiye Türkçesi, edebi dil, konuşma dili, yazı dili",
    "anahtarcı": "çilingir, kilitçi, anahtar ustası, kilit tamircisi, kapı açıcı, maymuncukçu, anahtar yapımcısı, kilit uzmanı, güvenlikçi, kasa açıcı, kapı ustası",
    "felemma": "ne zaman ki, vaktaki, ol vakit, o zaman, -ince, -unca, o anda, tam o sırada, o esnada, akabinde, derken, hemen ardından, sonucunda, neticesinde",
    "garson": "komi, servis elemanı, hizmetli, sofracı, masa görevlisi, servisçi, hizmetkar, ayakçı, şef garson, servis personeli, lokanta çalışanı, kafe görevlisi",
    "geliyorum": "yaklaşıyorum, varmak üzereyim, yoldayım, intikal ediyorum, teşrif ediyorum, ulaşmak üzereyim, gelmekteyim, yöneliyorum, dönüyorum, avdet ediyorum, buradayım",
    "girişken": "atılgan, faal, aktif, sosyal, medeni cesareti yüksek, inisiyatif alan, dışa dönük, cüretkar, hamleci, tuttuğunu koparan, becerikli, cevval, tez canlı",
    "gündem": "ajanda, takvim, yapılacaklar listesi, konu başlıkları, güncel konular, müzakere maddeleri, program, plan, iş listesi, ruzname, aktüalite, manşetler",
    "hakem": "yargıcı, arabulucu, uzlaştırıcı, karar verici, orta yol bulucu, hüküm veren, maçı yöneten, kadı, bilirkişi, jüri, heyet üyesi, değerlendirici",
    "hamburger": "köfteli sandviç, burger, etli ekmek, hazır yemek, fast food, sığır eti köftesi, peynirli burger, tavuk burger, Amerikan yemeği, ekmek arası köfte",
    "hamsi": "Karadeniz balığı, küçük balık, gümüş balığı, hamsi kuşu, hamsi tava, hamsi buğulama, deniz ürünü, kış balığı, sürü balığı, yerel lezzet",
    "helikopter": "döner kanat, pervaneli uçak, dikey kalkan uçak, uçan araç, hava taşıtı, pırpır, askeri helikopter, kurtarma helikopteri, ambulans helikopter, hava taksi"
}

def clean_word(w):
    return w.strip()

def main():
    if not os.path.exists(csv_path):
        print(f"❌ Dosya bulunamadı: {csv_path}")
        return

    print("Gemini 3 Pro Enrichment Simülasyonu çalışıyor...")
    
    updated_rows = []
    headers = []
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        if 'yeni_anlamlar_1_15' not in headers:
            headers.append('yeni_anlamlar_1_15')
            
        for row in reader:
            w = clean_word(row['kelime'])
            
            # Eğer kelime sözlüğümüzde varsa güncelle
            if w in enrichment_data:
                row['yeni_anlamlar_1_15'] = enrichment_data[w]
            
            # Bazı kelimeler küçük harf olabilir, kontrol et
            elif w.lower() in enrichment_data:
                row['yeni_anlamlar_1_15'] = enrichment_data[w.lower()]
                
            updated_rows.append(row)

    # Yazma işlemi
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(updated_rows)
        
    print(f"✅ {len(enrichment_data)} kelime için zengin anlamlar eklendi.")
    print("ℹ️ Diğer kelimeler için bu desenin devam ettirilmesi önerilir.")

if __name__ == '__main__':
    main()
