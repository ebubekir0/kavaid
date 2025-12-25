import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kavaid/widgets/email_auth_sheet.dart'; // Import eklendi
import 'package:kavaid/screens/legacy_book_texts_screen.dart';
import 'package:kavaid/screens/interactive_book_screen.dart';
import 'package:kavaid/services/book_store_service.dart';
import 'package:kavaid/services/purchase_manager.dart';
import 'package:kavaid/screens/subscription_screen.dart';

// Ana Model - Raf (Shelf) ve Kitap (Content)
class LibraryCategory {
  final String title;
  final List<LibraryContent> contents;

  LibraryCategory({required this.title, required this.contents});
}

class LibraryContent {
  final String id;
  final String title;
  final String arabicTitle;
  final String thumbnail; // assets/thumbnail_x.jpg
  final String author;
  final String level; // A1, A2, B1...
  final int wordCount;
  final String description;
  final bool isFree;
  final String bookId; // Mevcut kitap sistemi ID'si (örn: taysir_sira)

  LibraryContent({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.thumbnail,
    required this.author,
    required this.level,
    required this.wordCount,
    required this.description,
    this.isFree = true,
    required this.bookId,
  });
}

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // === ÖRNEK VERİLER (Youtube Tarzı) ===
  // Gerçekte bunlar bir servisten veya JSON'dan gelebilir.
  final List<LibraryCategory> _shelves = [
    LibraryCategory(
      title: "Ücretsiz İçerikler",
      contents: [
        LibraryContent(
          id: "3",
          title: "Hz. Yusuf ve Kardeşleri",
          arabicTitle: "يُوسُفُ وَإِخْوَتُهُ",
          thumbnail: "assets/images/hz_yusuf.jpg",
          author: "Kıssalar",
          level: "A1",
          wordCount: 136,
          description: "Kardeşlerinin kuyuya attığı Hz. Yusuf'un Mısır'da yönetici olması.",
          bookId: "hz_yusuf",
          isFree: true,
        ),
        LibraryContent(
          id: "14",
          title: "Don Kişot",
          arabicTitle: "دُون كِيشُوت",
          thumbnail: "assets/images/don kişot.jpeg",
          author: "Cervantes",
          level: "B1",
          wordCount: 312,
          description: "Don Kişot ve Sancho Panza'nın yeldeğirmenlerine karşı savaşı.",
          bookId: "don_kisot",
          isFree: true,
        ),
        LibraryContent(
          id: "30",
          title: "Babil'in Asma Bahçeleri",
          arabicTitle: "حَدَائِقُ بَابِلَ الْمُعَلَّقَةُ",
          thumbnail: "assets/images/babil.jpeg",
          author: "Tarih & Efsane",
          level: "C1",
          wordCount: 502,
          description: "Kral Nebukadnezar'ın memleket hasreti çeken eşi için yaptırdığı, mühendislik harikası sulama sistemiyle ünlü efsanevi bahçeler.",
          bookId: "babil_asma_bahceleri",
          isFree: true,
        ),
        LibraryContent(
          id: "5",
          title: "İlk Müezzin: Bilal-i Habeşi",
          arabicTitle: "الْمُؤَذِّنُ الْأَوَّلُ",
          thumbnail: "assets/images/bilal_habesi.jpg",
          author: "Sahabe",
          level: "A1",
          wordCount: 133,
          description: "Bilal-i Habeşi'nin kölelikten kurtulup ilk müezzin olması.",
          bookId: "bilal_habesi",
          isFree: true,
        ),
        LibraryContent(
          id: "19",
          title: "Hz. Musa ve Hızır",
          arabicTitle: "رِحْلَةُ مُوسَى وَالْخِضْرِ",
          thumbnail: "assets/images/hz musa hızır.jpeg",
          author: "Kuran Kıssası",
          level: "B1",
          wordCount: 348,
          description: "Hz. Musa ve Hz. Hızır'ın gizemli ve hikmet dolu yolculuğu.",
          bookId: "hz_musa_ve_hizirin_yolculugu",
          isFree: true,
        ),
        LibraryContent(
          id: "32",
          title: "Frankenstein",
          arabicTitle: "فْرَانْكِشْتَايْن",
          thumbnail: "assets/images/franeknstein.jpeg",
          author: "Mary Shelley",
          level: "C1",
          wordCount: 503,
          description: "Bilim insanı Victor Frankenstein'ın yarattığı yaratığın, toplum tarafından dışlanması sonucu iyi kalpli bir varlıktan intikamcı bir canavara dönüşmesi.",
          bookId: "frankenstein",
          isFree: true,
        ),
      ],
    ),
    LibraryCategory(
      title: "Giriş Seviyesi",
      contents: [
        LibraryContent(
          id: "12",
          title: "Peygamber ve Ağlayan Kütük",
          arabicTitle: "النَّبِيُّ وَالْجِذْعُ",
          thumbnail: "assets/images/aglayan_kutuk.jpg",
          author: "Siyer",
          level: "A1",
          wordCount: 139,
          description: "Hz. Muhammed hutbe okurken terk ettiği hurma kütüğünün ağlaması ve Peygamberin onu kucaklayarak teselli etmesi.",
          bookId: "aglayan_kutuk",
          isFree: false,
        ),
        LibraryContent(
          id: "11",
          title: "Osmanlı'da Sadaka Taşı",
          arabicTitle: "حَجَرُ الصَّدَقَةِ",
          thumbnail: "assets/images/sadaka_tasi.jpg",
          author: "Tarih",
          level: "A1",
          wordCount: 128,
          description: "Osmanlı'da zenginlerin gizlice para bıraktığı, fakirlerin ise sadece ihtiyacı kadar aldığı yardımlaşma taşı anlatılıyor.",
          bookId: "sadaka_tasi",
          isFree: false,
        ),
        LibraryContent(
          id: "10",
          title: "Mevlana ve Sevgi",
          arabicTitle: "مَوْلَانَا وَالْمَحَبَّةُ",
          thumbnail: "assets/images/mevlana_sevgi.jpg",
          author: "Tasavvuf",
          level: "A1",
          wordCount: 130,
          description: "Mevlana Celaleddin Rumi'nin insan sevgisi ve hoşgörüsü.",
          bookId: "mevlana_sevgi",
          isFree: false,
        ),
        LibraryContent(
          id: "9",
          title: "Dürüst Tüccarlar",
          arabicTitle: "التُّجَّارُ الصَّادِقُونَ",
          thumbnail: "assets/images/durust_tuccarlar.jpg",
          author: "Ahlak",
          level: "A1",
          wordCount: 133,
          description: "Arazi satışında bulunan altını birbirine vermek isteyen dürüst insanlar.",
          bookId: "durust_tuccarlar",
          isFree: false,
        ),
        LibraryContent(
          id: "8",
          title: "Mağaradaki Örümcek",
          arabicTitle: "الْعَنْكَبُوتُ فِي الْغَارِ",
          thumbnail: "assets/images/magaradaki_orumcek.jpg",
          author: "Siyer",
          level: "A1",
          wordCount: 137,
          description: "Hicret sırasında Sevr mağarasına saklanan Hz. Muhammed'i koruyan örümcek.",
          bookId: "magaradaki_orumcek",
          isFree: false,
        ),
        LibraryContent(
          id: "7",
          title: "İbn-i Sina ve Tıp",
          arabicTitle: "ابْنُ سِينَا وَالطِّبُّ",
          thumbnail: "assets/images/ibni_sina.jpg",
          author: "Bilim",
          level: "A1",
          wordCount: 138,
          description: "İbn-i Sina'nın sultanı iyileştirmesi ve kütüphane sevgisi.",
          bookId: "ibni_sina",
          isFree: false,
        ),
        LibraryContent(
          id: "6",
          title: "Susuz Köpek ve Adam",
          arabicTitle: "الْكَلْبُ الْعَطْشَانُ",
          thumbnail: "assets/images/susuz_kopek.jpg",
          author: "Hadis",
          level: "A1",
          wordCount: 131,
          description: "Çölde susuz bir köpeğe su içiren adamın hikayesi.",
          bookId: "susuz_kopek",
          isFree: false,
        ),
        LibraryContent(
          id: "5",
          title: "İlk Müezzin: Bilal-i Habeşi",
          arabicTitle: "الْمُؤَذِّنُ الْأَوَّلُ",
          thumbnail: "assets/images/bilal_habesi.jpg",
          author: "Sahabe",
          level: "A1",
          wordCount: 133,
          description: "Bilal-i Habeşi'nin kölelikten kurtulup ilk müezzin olması.",
          bookId: "bilal_habesi",
          isFree: false,
        ),
        LibraryContent(
          id: "4",
          title: "Mimar Sinan'ın Zekası",
          arabicTitle: "ذَكَاءُ الْمِعْمَارِ سِنَان",
          thumbnail: "assets/images/mimar_sinan.jpg",
          author: "Tarih",
          level: "A1",
          wordCount: 128,
          description: "Mimar Sinan'ın Süleymaniye Camii'nin akustiğini test etmesi.",
          bookId: "mimar_sinan",
          isFree: false,
        ),
        LibraryContent(
          id: "3",
          title: "Hz. Yusuf ve Kardeşleri",
          arabicTitle: "يُوسُفُ وَإِخْوَتُهُ",
          thumbnail: "assets/images/hz_yusuf.jpg",
          author: "Kıssalar",
          level: "A1",
          wordCount: 136,
          description: "Kardeşlerinin kuyuya attığı Hz. Yusuf'un Mısır'da yönetici olması.",
          bookId: "hz_yusuf",
          isFree: false,
        ),
      ],
    ),
    LibraryCategory(
      title: "Orta Seviye",
      contents: [
        LibraryContent(
          id: "13",
          title: "Alice Harikalar Diyarında",
          arabicTitle: "أَلِيس فِي بِلَادِ الْعَجَائِبِ",
          thumbnail: "assets/images/alice.jpeg",
          author: "Lewis Carroll",
          level: "B1",
          wordCount: 310,
          description: "Tavşanı takip ederek deliğe düşen Alice'in fantastik dünyadaki maceraları.",
          bookId: "alice_harikalar_diyarinda",
          isFree: false,
        ),
        LibraryContent(
          id: "18",
          title: "Seksen Günde Devrialem",
          arabicTitle: "حَوْلَ الْعَالَمِ فِي ثَمَانِينَ يَوْمًا",
          thumbnail: "assets/images/seksen güdne devrialem.jpeg",
          author: "Jules Verne",
          level: "B1",
          wordCount: 315,
          description: "Phileas Fogg'un dünyayı 80 günde dolaşma iddiası ve maceraları.",
          bookId: "seksen_gunde_devrialem",
          isFree: false,
        ),
        LibraryContent(
          id: "22",
          title: "Sherlock Holmes'un Zekası",
          arabicTitle: "ذَكَاءُ شِيرْلُوك هُولْمِز",
          thumbnail: "assets/images/sherlock.jpeg",
          author: "Arthur Doyle",
          level: "B1",
          wordCount: 298,
          description: "Dedektif Holmes'un müthiş gözlem yeteneğiyle bir sırrı açığa çıkarması.",
          bookId: "sherlock_holmesun_zekasi",
          isFree: false,
        ),
        LibraryContent(
          id: "21",
          title: "Robinson Crusoe",
          arabicTitle: "رُوبِنْسُن كُرُوزُو",
          thumbnail: "assets/images/robinson cruoise.jpeg",
          author: "Daniel Defoe",
          level: "B1",
          wordCount: 302,
          description: "Issız adaya düşen Robinson'un hayatta kalma mücadelesi ve Cuma ile tanışması.",
          bookId: "robinson_crusoe",
          isFree: false,
        ),
        LibraryContent(
          id: "20",
          title: "Küçük Prens",
          arabicTitle: "الْأَمِيرُ الصَّغِيرُ",
          thumbnail: "assets/images/küçük prens.jpeg",
          author: "Exupery",
          level: "B1",
          wordCount: 286,
          description: "Küçük Prens'in gezegeninden ayrılıp dünyaya gelmesi ve tilkiyle dostluğu.",
          bookId: "kucuk_prens",
          isFree: false,
        ),
        LibraryContent(
          id: "19",
          title: "Hz. Musa ve Hızır",
          arabicTitle: "رِحْلَةُ مُوسَى وَالْخِضْرِ",
          thumbnail: "assets/images/hz musa hızır.jpeg",
          author: "Kuran Kıssası",
          level: "B1",
          wordCount: 348,
          description: "Hz. Musa ve Hz. Hızır'ın gizemli ve hikmet dolu yolculuğu.",
          bookId: "hz_musa_ve_hizirin_yolculugu",
          isFree: false,
        ),
        LibraryContent(
          id: "17",
          title: "Monte Kristo Kontu",
          arabicTitle: "الْكُونْت دِي مُونْتِ كِرِيسْتُو",
          thumbnail: "assets/images/monte krito kontu.jpeg",
          author: "Alexandre Dumas",
          level: "B1",
          wordCount: 318,
          description: "İftiraya uğrayan Edmond Dantes'in hapisten kaçışı ve intikam planı.",
          bookId: "monte_kristo_kontu",
          isFree: false,
        ),
        LibraryContent(
          id: "16",
          title: "Yaşlı Adam ve Deniz",
          arabicTitle: "الْعَجُوزُ وَالْبَحْرُ",
          thumbnail: "assets/images/yaşlı balıkçı.jpeg",
          author: "Hemingway",
          level: "B1",
          wordCount: 315,
          description: "Yaşlı balıkçı Santiago'nun dev bir balıkla amansız mücadelesi.",
          bookId: "yasli_adam_ve_deniz",
          isFree: false,
        ),
        LibraryContent(
          id: "15",
          title: "Oliver Twist",
          arabicTitle: "أُولِيفَرْ تُوِيِسْت",
          thumbnail: "assets/images/oliver twist.jpeg",
          author: "Charles Dickens",
          level: "B1",
          wordCount: 312,
          description: "Yetim Oliver'ın Londra sokaklarındaki zorlu yaşamı ve kurtuluşu.",
          bookId: "oliver_twist",
          isFree: false,
        ),
        LibraryContent(
          id: "14",
          title: "Don Kişot",
          arabicTitle: "دُون كِيشُوت",
          thumbnail: "assets/images/don kişot.jpeg",
          author: "Cervantes",
          level: "B1",
          wordCount: 312,
          description: "Don Kişot ve Sancho Panza'nın yeldeğirmenlerine karşı savaşı.",
          bookId: "don_kisot",
          isFree: false,
        ),
      ],
    ),
    LibraryCategory(
      title: "İleri Seviye",
      contents: [
        LibraryContent(
          id: "29",
          title: "Savaş ve Barış",
          arabicTitle: "الْحَرْبُ وَالسَّلَامُ",
          thumbnail: "assets/images/savaş ve barış.jpeg",
          author: "Leo Tolstoy",
          level: "C1",
          wordCount: 505,
          description: "Napolyon'un Rusya'yı işgali sırasında beş aristokrat ailenin değişen hayatları, savaşın anlamsızlığı ve karakterlerin içsel yolculukları.",
          bookId: "savas_ve_baris",
          isFree: false,
        ),
        LibraryContent(
          id: "25",
          title: "Romeo ve Juliet",
          arabicTitle: "رُومِيُو وَجُولْيِيت",
          thumbnail: "assets/images/romeo ve julitet.jpeg",
          author: "William Shakespeare",
          level: "C1",
          wordCount: 501,
          description: "İti düşman ailenin çocukları olan Romeo ve Juliet'in trajik aşkı, gizli evlilikleri ve yanlış anlaşılmalar sonucu intiharları.",
          bookId: "romeo_ve_juliet",
          isFree: false,
        ),
        LibraryContent(
          id: "32",
          title: "Frankenstein",
          arabicTitle: "فْرَانْكِشْتَايْن",
          thumbnail: "assets/images/franeknstein.jpeg",
          author: "Mary Shelley",
          level: "C1",
          wordCount: 503,
          description: "Bilim insanı Victor Frankenstein'ın yarattığı yaratığın, toplum tarafından dışlanması sonucu iyi kalpli bir varlıktan intikamcı bir canavara dönüşmesi.",
          bookId: "frankenstein",
          isFree: false,
        ),
        LibraryContent(
          id: "31",
          title: "İmam Gazali",
          arabicTitle: "الْإِمَامُ الْغَزَالِيُّ",
          thumbnail: "assets/images/imam gazali.jpeg",
          author: "İslam Alimleri",
          level: "C1",
          wordCount: 507,
          description: "Ünlü alim Gazali'nin şöhretin zirvesindeyken geçirdiği manevi kriz, her şeyi bırakıp inzivaya çekilmesi ve 'İhya' eserini yazması.",
          bookId: "imam_gazali",
          isFree: false,
        ),
        LibraryContent(
          id: "30",
          title: "Babil'in Asma Bahçeleri",
          arabicTitle: "حَدَائِقُ بَابِلَ الْمُعَلَّقَةُ",
          thumbnail: "assets/images/babil.jpeg",
          author: "Tarih & Efsane",
          level: "C1",
          wordCount: 502,
          description: "Kral Nebukadnezar'ın memleket hasreti çeken eşi için yaptırdığı, mühendislik harikası sulama sistemiyle ünlü efsanevi bahçeler.",
          bookId: "babil_asma_bahceleri",
          isFree: false,
        ),
        LibraryContent(
          id: "28",
          title: "Barbaros Hayrettin",
          arabicTitle: "خَيْرُ الدِّينِ بَرْبَرُوس",
          thumbnail: "assets/images/barbaros.jpeg",
          author: "Tarihi Şahsiyetler",
          level: "C1",
          wordCount: 506,
          description: "Osmanlı'nın büyük denizcisi Barbaros Hayrettin'in Endülüs'ten insanları kurtarması ve Preveze Deniz Savaşı'ndaki efsanevi zaferi.",
          bookId: "barbaros_hayrettin",
          isFree: false,
        ),
        LibraryContent(
          id: "27",
          title: "Dönüşüm",
          arabicTitle: "الْمَسْخُ (كَافْكَا)",
          thumbnail: "assets/images/dönüşüm.jpeg",
          author: "Franz Kafka",
          level: "C1",
          wordCount: 509,
          description: "Gregor Samsa'nın bir sabah böceğe dönüşmesi, ailesinin ona karşı değişen tavrı, yaşadığı yabancılaşma ve trajik ölümü.",
          bookId: "donusum_kafka",
          isFree: false,
        ),
        LibraryContent(
          id: "26",
          title: "Titanik'in Batışı",
          arabicTitle: "غَرَقُ سَفِينَةِ تِيتَانِيك",
          thumbnail: "assets/images/titanik.jpeg",
          author: "Tarih",
          level: "C1",
          wordCount: 505,
          description: "Batmaz denilen Titanik'in ilk seferinde buzdağına çarpıp batması, yetersiz filikalar ve yaşanan büyük insanlık trajedisi.",
          bookId: "titanik",
          isFree: false,
        ),
        LibraryContent(
          id: "24",
          title: "İbn-i Battuta",
          arabicTitle: "رِحْلَاتُ ابْنِ بَطُّوطَةَ",
          thumbnail: "assets/images/ibni batuta.jpeg",
          author: "Tarih",
          level: "C1",
          wordCount: 512,
          description: "Faslı gezgin İbn-i Battuta'nın Hac niyetiyle başlayıp Çin'e kadar uzanan 29 yıllık efsanevi yolculuğu.",
          bookId: "ibni_battuta",
          isFree: false,
        ),
        LibraryContent(
          id: "23",
          title: "Ashab-ı Kehf",
          arabicTitle: "أَصْحَابُ الْكَهْفِ",
          thumbnail: "assets/images/ashabu kehf.jpeg",
          author: "Kuran Kıssası",
          level: "C1",
          wordCount: 508,
          description: "İnançları uğruna mağaraya sığınan gençlerin 309 yıl uyutulup tekrar uyandırılmaları.",
          bookId: "ashabi_kehf",
          isFree: false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final primaryBlue = isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      // Standart Mavi Header
      appBar: AppBar(
        title: Text(
          "Öğren",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: Consumer<PurchaseManager>(
          builder: (context, pm, _) {
            // Sadece satın alınmış kitabı varsa göster
            if (pm.purchasedBooks.isEmpty) return const SizedBox.shrink();
            
            return IconButton(
              icon: const Icon(Icons.auto_stories_rounded, color: Colors.white),
              tooltip: "Satın Aldıklarım",
              onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const PurchasedBooksScreen()),
                 );
              },
            );
          },
        ),
        actions: [
          // Premium İkonu
          Consumer<PurchaseManager>(
            builder: (context, purchaseManager, _) {
              if (purchaseManager.isPremium) return const SizedBox.shrink(); // Zaten premium ise gösterme (opsiyonel)
              
              return GestureDetector(
                onTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    // Kayıt ol sekmesi varsayılan olarak açılsın, uyarı yok
                    EmailAuthSheet.show(
                      context, 
                      initialIsLogin: false,
                      message: "Önce kayıt olup giriş yapmalısınız."
                    );
                  } else {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)], // Mavi gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16), // Yıldızlı efekt ikonu
                      const SizedBox(width: 4),
                      Text(
                        "PREMIUM'A GEÇ", // Tıklanabilir olduğu daha belli olsun
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16), // Ok işareti ekle
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PurchaseManager>(
        builder: (context, purchaseManager, _) {
          // Premium kullanıcılar için "Ücretsiz İçerikler" rafını gizle
          final displayShelves = purchaseManager.isPremium 
              ? _shelves.where((s) => s.title != "Ücretsiz İçerikler").toList() 
              : _shelves;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80), 
            itemCount: displayShelves.length,
            itemBuilder: (context, index) {
              final shelf = displayShelves[index];
              return _buildShelf(shelf, textColor, primaryBlue, purchaseManager);
            },
          );
        },
      ),
    );
  }

  Widget _buildShelf(LibraryCategory shelf, Color textColor, Color accentColor, PurchaseManager purchaseManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Raf Başlığı
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), 
          child: Text(
            shelf.title,
            style: GoogleFonts.outfit(
              fontSize: 19, 
              fontWeight: FontWeight.w800,
              color: textColor.withOpacity(0.9),
              letterSpacing: -0.5,
            ),
          ),
        ),

        // Yatay Liste
        SizedBox(
          height: 185, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shelf.contents.length,
            itemBuilder: (context, index) {
              final content = shelf.contents[index];
              // Kilit mantığı güncellendi: canAccessContent metodunu kullan
              final bool isLocked = !purchaseManager.canAccessContent(content.bookId, content.isFree);
              
              return _buildContentCard(content, textColor, isLocked, accentColor);
            },
          ),
        ),
        // Raflar arası ince çizgi ayracı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: textColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(LibraryContent content, Color textColor, bool isLocked, Color primaryBlue) {
    const double cardWidth = 220;
    const double thumbnailHeight = 135; 

    return GestureDetector(
      onTap: () {
         // Her türlü detay sayfasını aç, kilit kontrolü "Okumaya Başla" butonunda yapılacak
         _showContentDetail(content, isLocked);
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 14),
        color: Colors.transparent, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: thumbnailHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), // Daha yuvarlak
                color: Colors.grey.withOpacity(0.15), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                image: content.thumbnail.isNotEmpty && !content.thumbnail.contains("placeholder")
                    ? DecorationImage(
                        image: AssetImage(content.thumbnail),
                        fit: BoxFit.cover,
                        onError: (obj, stack) {}
                      )
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (content.thumbnail.isEmpty || content.thumbnail.contains("placeholder"))
                    Center(
                      child: Text(
                        content.title.substring(0, 1),
                        style: GoogleFonts.gemunuLibre(
                          fontSize: 40,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                    if (isLocked)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  
                  // Seviye Badge'i (Sağ Üst)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        content.level,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Başlık
            Text(
              content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 15, // Daha büyük
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detay Modal (Youtube Short tarzı alttan açılır)
  void _showContentDetail(LibraryContent content, bool isLocked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentDetailSheet(content: content, isLocked: isLocked),
    );
  }

  void _showLoginWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Oturum Açın", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "Bu özelliğe erişmek için lütfen önce kayıt olun veya giriş yapın.",
          style: GoogleFonts.outfit(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tamam", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPremiumLockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF1976D2)),
            const SizedBox(height: 16),
            Text(
              "Bu İçerik Premium'a Dahil",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Bu dersi okumak için premium üyeliğe geçmelisin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Premium'a Geç", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
             const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Ücretsiz İçeriklere Dön", style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}


class _ContentDetailSheet extends StatelessWidget {
  final LibraryContent content;
  final bool isLocked;

  const _ContentDetailSheet({required this.content, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final primaryBlue = const Color(0xFF1976D2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÜST KISIM: Büyük Resim + Kapat Butonu + Tutamaç
          Stack(
            children: [
              // Arka Plan Resmi (Blur efektli olabilir veya direkt resim)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  image: content.thumbnail.isNotEmpty && !content.thumbnail.contains("placeholder")
                      ? DecorationImage(
                          image: AssetImage(content.thumbnail),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        )
                      : null,
                  color: content.thumbnail.isEmpty ? Colors.grey[800] : null,
                ),
              ),

              // Tutamaç
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // İçerik Başlığı (Resmin üzerine - Sadece İsim)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Text(
                  content.title,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                       Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10),
                    ]
                  ),
                ),
              ),
            ],
          ),

          // ALT KISIM: Açıklama ve Buton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İçerik Başlığı + Kelime Sayısı + Dil Seviyesi
                  Row(
                    children: [
                      Text(
                        "İçerik",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      // Kelime Sayısı Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${content.wordCount} Kelime",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dil Seviyesi Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content.level,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Açıklama Metni
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        content.description,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: textColor.withOpacity(0.8),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // OKU Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // KONTROLLER BURADA YAPILIYOR
                        if (content.isFree) {
                           // Ücretsiz
                           _openReader(context);
                        } else {
                           final user = FirebaseAuth.instance.currentUser;
                           if (user == null) {
                             // Giriş uyarısı (mevcut snackbar/toast yerine dialog)
                             _showLoginWarningInSheet(context);
                           } else {
                             if (isLocked) {
                               // Premium uyarısı
                               _showPremiumWarningInSheet(context);
                             } else {
                               // Giriş var + Premium = Aç
                               _openReader(context);
                             }
                           }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryBlue.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            "Okumaya Başla",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
       children: [
         Icon(icon, size: 20, color: Colors.grey),
         const SizedBox(width: 6),
         Text(
           text,
           style: GoogleFonts.outfit(
             fontSize: 14,
             fontWeight: FontWeight.w500,
             color: color,
           ),
         ),
       ],
    );
  }

  void _openReader(BuildContext context) {
    Navigator.pop(context); // Modalı kapat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveBookScreen(
          bookId: content.bookId,
          bookTitle: content.title,
          arabicTitle: content.arabicTitle,
          thumbnail: content.thumbnail,
        ),
      ),
    );
  }

  void _showLoginWarningInSheet(BuildContext context) {
    // Auth sheet'i direkt mesajla aç
    EmailAuthSheet.show(
      context, 
      initialIsLogin: false, // Kullanıcı kayıt ol açılsın istedi
      message: "Önce kayıt olup giriş yapmalısınız.",
      onSuccess: () {
        // Başarılı giriş/kayıt sonrası detay sayfasını kapatıp yenilemek isteyebiliriz
        // veya direkt okumaya geçebiliriz. Şimdilik sadece sheet kapanıyor.
        Navigator.pop(context); // Detay sheet'ini kapat
      },
    );
  }


  void _showPremiumWarningInSheet(BuildContext context) {
     Navigator.pop(context); // Sheet'i kapat
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF1976D2)),
            const SizedBox(height: 16),
            Text(
              "Premium İçerik",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Bu içeriğe erişmek için Premium aboneliğe geçmelisiniz.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Dialogu kapat
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Premium'a Geç", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
             const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Ücretsiz İçeriklere Dön", style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchasedBooksScreen extends StatefulWidget {
  const PurchasedBooksScreen({super.key});

  @override
  State<PurchasedBooksScreen> createState() => _PurchasedBooksScreenState();
}

class _PurchasedBooksScreenState extends State<PurchasedBooksScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshPurchases(BuildContext context) async {
    setState(() => _isRefreshing = true);
    try {
      // PurchaseManager'ı manuel olarak tetikle
      await Provider.of<PurchaseManager>(context, listen: false).initialize();
      // Veritabanından tekrar çek
      await Provider.of<PurchaseManager>(context, listen: false).loadUserPurchases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Satın almalar güncellendi.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final primaryBlue = isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Kütüphanem",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: const [],
      ),
      body: Consumer<PurchaseManager>(
        builder: (context, pm, _) {
          final List<LibraryContent> myBooks = [];
          
          final userPurchasedIds = pm.purchasedBooks.map((e) => e.toLowerCase()).toList();
          debugPrint('🔍 [PurchasedBooksScreen] Loaded IDs: $userPurchasedIds');

          final kiraatBooks = [
            {'id': 'kiraah_1', 'title': "Kitabü'l Kıraat 1", 'sub': '1. Seviye'},
            {'id': 'kiraah_2', 'title': "Kitabü'l Kıraat 2", 'sub': '2. Seviye'},
            {'id': 'kiraah_3', 'title': "Kitabü'l Kıraat 3", 'sub': '3. Seviye'},
            {'id': 'taysir_sira', 'title': "Kitabü'l Kıraat (Siyer)", 'sub': 'Taysir Sira'},
          ];

          for (var item in kiraatBooks) {
            final searchId = item['id']!;
            // Daha esnek eşleşme: ID içinde kiraah_1 geçiyorsa kabul et
            if (userPurchasedIds.any((id) => id.contains(searchId))) {
               myBooks.add(
                 LibraryContent(
                    id: "legacy_$searchId",
                    title: item['title']!,
                    arabicTitle: "كِتَابُ الْقِرَاءَةِ",
                    thumbnail: "assets/images/${searchId == 'taysir_sira' ? 'taysir_sira' : 'placeholder_book'}.jpg", 
                    author: "Eski Müfredat",
                    level: "Seviye",
                    wordCount: 0,
                    description: "${item['sub']} dersleri.",
                    bookId: searchId == 'taysir_sira' ? 'taysir_sira' : 'kitab_$searchId',
                    isFree: false, 
                 ),
               );
            }
          }

          if (pm.purchasedBooks.any((id) => id.toLowerCase().contains('siyer_nebi'))) {
             myBooks.add(
               LibraryContent(
                  id: "legacy_siyer",
                  title: "Siyer-i Nebi",
                  arabicTitle: "سِيرَةُ النَّبِيِّ",
                  thumbnail: "assets/images/siyer_nebi.jpg", 
                  author: "Eski Müfredat",
                  level: "B1",
                  wordCount: 0,
                  description: "Daha önce satın aldığınız Siyer-i Nebi dersleri.",
                  bookId: "siyer_nebi",
                  isFree: false, 
               ),
             );
          }
          
          if (myBooks.isEmpty && !_isRefreshing) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.library_books_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text(
                     "Satın alınmış kitap bulunamadı.",
                     style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                   ),
                   const SizedBox(height: 12),
                   ElevatedButton.icon(
                      onPressed: () => _refreshPurchases(context),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Satın Almaları Kontrol Et"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                   ),
                 ],
               ),
             );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: myBooks.length,
            itemBuilder: (context, index) {
              final book = myBooks[index];
              return GestureDetector(
                onTap: () {
                    // Legacy kitaplar için eski ekranı aç
                    // bookId: "taysir_sira" veya "kitab_kiraah_1" gibi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LegacyBookTextsScreen(
                          bookId: book.bookId,
                          bookTitle: book.title,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            color: Colors.grey.shade200,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.asset(
                                    book.thumbnail, 
                                    fit: BoxFit.cover, 
                                    errorBuilder: (c,o,s) => Center(
                                      child: Icon(Icons.book, size: 40, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Satın Alındı",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
