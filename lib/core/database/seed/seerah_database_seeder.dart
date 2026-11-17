import 'package:sqflite/sqflite.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_01_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_02_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_03_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_04_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_05_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_06_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_07_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_08_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_09_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_10_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_11_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_12_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_13_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_14_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_15_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/chapters/chapter_16_seed.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_seed_types.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

/// Ordered registry of all 16 researched Urdu & Pashto Seerah chapters.
const List<SeedChapterContent> allChapterSeeds = <SeedChapterContent>[
  chapterOneSeed,
  chapterTwoSeed,
  chapterThreeSeed,
  chapterFourSeed,
  chapterFiveSeed,
  chapterSixSeed,
  chapterSevenSeed,
  chapterEightSeed,
  chapterNineSeed,
  chapterTenSeed,
  chapterElevenSeed,
  chapterTwelveSeed,
  chapterThirteenSeed,
  chapterFourteenSeed,
  chapterFifteenSeed,
  chapterSixteenSeed,
];

/// Idempotent offline-first seeder that populates all 16 researched Urdu &
/// Pashto Seerah chapters, primary sources, narrators, timeline events, and
/// claim evidence into SQLite.
final class SeerahDatabaseSeeder {
  SeerahDatabaseSeeder(this._db);

  final AppDatabase _db;

  Future<void> seedInitialContentIfEmpty() async {
    final db = await _db.database;
    final existingChapters = await db.query('chapters', columns: ['stable_id']);
    final existingChapterIds = existingChapters
        .map((c) => AppDatabase.readString(c['stable_id']))
        .toSet();
    final existingVersions = await db.query(
      'research_versions',
      columns: ['version_tag'],
    );
    final hasEncyclopedicV2 = existingVersions.any(
      (v) =>
          AppDatabase.readString(v['version_tag']) ==
          'v2.0.0-encyclopedic-seerah',
    );

    await db.transaction((txn) async {
      await _seedSupportedLanguages(txn);
      await _seedSources(txn);

      for (final chapter in allChapterSeeds) {
        if (!existingChapterIds.contains(chapter.stableId)) {
          await insertChapterContent(txn, chapter);
        } else if (!hasEncyclopedicV2) {
          await insertChapterContent(txn, chapter, upsertContent: true);
        }
      }

      await _seedPashtoChapterTranslations(txn);
      await _seedInitialResearchVersions(txn);
    });

    await db.transaction((txn) async {
      await _seedNarrationsAndLinks(txn);
    });

    await db.transaction((txn) async {
      await _seedTimelineLocationsAndCrossRefs(txn);
    });

    await db.transaction((txn) async {
      await _seedNarrationsAndPronunciation(txn);
    });
  }

  Future<void> _seedSources(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'src_quran',
          'title_arabic': 'القرآن الكريم',
          'title_urdu': 'قرآنِ کریم',
          'author_arabic': 'وحي إلهي',
          'author_urdu': 'کلامِ الٰہی',
          'tradition': 'sunni',
          'source_type': 'quran',
        },
        {
          'stable_id': 'src_ibn_hisham',
          'title_arabic': 'السيرة النبوية لابن هشام',
          'title_urdu': 'سیرت ابنِ ہشام',
          'author_arabic': 'عبد الملك بن هشام',
          'author_urdu': 'عبدالملک بن ہشام',
          'tradition': 'classical_history',
          'author_death_hijri': 218,
          'source_type': 'seerah',
        },
        {
          'stable_id': 'src_ibn_sad',
          'title_arabic': 'الطبقات الكبرى',
          'title_urdu': 'طبقاتِ ابنِ سعد',
          'author_arabic': 'محمد بن سعد',
          'author_urdu': 'محمد بن سعد',
          'tradition': 'classical_history',
          'author_death_hijri': 230,
          'source_type': 'seerah',
        },
        {
          'stable_id': 'src_tabari',
          'title_arabic': 'تاريخ الرسل والملوك',
          'title_urdu': 'تاریخِ طبری',
          'author_arabic': 'محمد بن جرير الطبري',
          'author_urdu': 'امام محمد بن جریر طبری',
          'tradition': 'classical_history',
          'author_death_hijri': 310,
          'source_type': 'tarikh',
        },
        {
          'stable_id': 'src_bukhari',
          'title_arabic': 'الجامع الصحيح (صحيح البخاري)',
          'title_urdu': 'صحیح بخاری',
          'author_arabic': 'محمد بن إسماعيل البخاري',
          'author_urdu': 'امام محمد بن اسماعیل بخاری',
          'tradition': 'sunni',
          'author_death_hijri': 256,
          'source_type': 'hadith',
        },
        {
          'stable_id': 'src_muslim',
          'title_arabic': 'المسند الصحيح (صحيح مسلم)',
          'title_urdu': 'صحیح مسلم',
          'author_arabic': 'مسلم بن الحجاج النيسابوري',
          'author_urdu': 'امام مسلم بن حجاج نیشاپوری',
          'tradition': 'sunni',
          'author_death_hijri': 261,
          'source_type': 'hadith',
        },
        {
          'stable_id': 'src_yaqubi',
          'title_arabic': 'تاريخ اليعقوبي',
          'title_urdu': 'تاریخِ یعقوبی',
          'author_arabic': 'أحمد بن أبي يعقوب اليعقوبي',
          'author_urdu': 'احمد بن ابی یعقوب اليعقوبي',
          'tradition': 'shia',
          'author_death_hijri': 292,
          'source_type': 'tarikh',
        },
        {
          'stable_id': 'src_musnad_ahmad',
          'title_arabic': 'المسند للإمام أحمد بن حنبل',
          'title_urdu': 'مسندِ امام احمد',
          'author_arabic': 'الإمام أحمد بن حنبل',
          'author_urdu': 'امام احمد بن حنبل رحمہ اللہ',
          'tradition': 'sunni',
          'author_death_hijri': 241,
          'source_type': 'hadith',
        },
        {
          'stable_id': 'src_tirmidhi',
          'title_arabic': 'الشمائل المحمدية وسنن الترمذي',
          'title_urdu': 'شمائلِ ترمذی و جامع ترمذی',
          'author_arabic': 'أبو عيسى محمد بن عيسى الترمذي',
          'author_urdu': 'امام ابو عیسیٰ محمد بن عیسیٰ ترمذی رحمہ اللہ',
          'tradition': 'sunni',
          'author_death_hijri': 279,
          'source_type': 'hadith',
        },
      ]) {
      batch.insert('sources', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'ref_quran_fil',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الفیل (105: 1–5)',
          'original_arabic_excerpt': 'أَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِأَصْحَابِ الْفِيلِ',
          'urdu_translation': 'کیا آپ نے نہیں دیکھا کہ آپ کے رب نے ہاتھی والوں کے ساتھ کیا معاملہ فرمایا۔',
        },
        {
          'stable_id': 'ref_ibn_hisham_lineage',
          'source_stable_id': 'src_ibn_hisham',
          'section_or_hadith_number': 'ذكر نسب رسول الله ﷺ',
          'urdu_translation': 'رسول اللہ ﷺ کا نسبِ مبارک عدنان تک متفقہ طور پر منقول ہے۔',
        },
        {
          'stable_id': 'ref_ibn_sad_abdullah',
          'source_stable_id': 'src_ibn_sad',
          'section_or_hadith_number': 'ذكر تزوج عبد الله بن عبد المطلب آمنة',
          'urdu_translation': 'حضرت عبداللہ اور سیدہ آمنہ کے نکاح، سفرِ شام اور مدینہ میں وفات کا تذکرہ۔',
        },
        {
          'stable_id': 'ref_tabari_vow',
          'source_stable_id': 'src_tabari',
          'section_or_hadith_number': 'نذر عبد المطلب',
          'urdu_translation': 'عبدالمطلب کی نذر اور قرعہ اندازی سے متعلق روایات میں اسنادی اور تفصیلی اختلافات موجود ہیں۔',
        },
        {
          'stable_id': 'ref_muslim_monday',
          'source_stable_id': 'src_muslim',
          'section_or_hadith_number': 'كتاب الصيام — باب استحباب صيام ثلاثة أيام',
          'original_arabic_excerpt': 'ذَاكَ يَوْمٌ وُلِدْتُ فِيهِ، وَيَوْمٌ بُعِثْتُ أَوْ أُنْزِلَ عَلَيَّ فِيهِ',
          'urdu_translation': 'پیر کے دن کے روزے کے بارے میں آپ ﷺ نے فرمایا: یہی وہ دن ہے جس میں میری ولادت ہوئی اور اسی میں مجھ پر وحی نازل ہوئی۔',
        },
        {
          'stable_id': 'ref_bukhari_thuwaybah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب النكاح — وأمهاتكم اللاتي أرضعنكم',
          'urdu_translation': 'حضرت ثویبہ رضی اللہ عنہا کے دودھ پلانے کی صحیح روایت۔',
        },
        {
          'stable_id': 'ref_ibn_hisham_halimah',
          'source_stable_id': 'src_ibn_hisham',
          'section_or_hadith_number': 'رضاعته ﷺ في بني سعد',
          'urdu_translation': 'قبیلۂ بنی سعد میں سیدہ حلیمہ سعدیہ کے پاس پرورش اور رضاعت کا بیان۔',
        },
        {
          'stable_id': 'ref_yaqubi_birth_date',
          'source_stable_id': 'src_yaqubi',
          'section_or_hadith_number': 'ولادة النبي ﷺ',
          'urdu_translation': 'تاریخِ ولادت کے دن اور مہینے کے بارے میں مؤرخین کے متعدد اقوال کا ذکر۔',
        },
        {
          'stable_id': 'ref_bukhari_shepherd',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب الإجارة — باب رعي الغنم على قراريط',
          'original_arabic_excerpt': 'مَا بَعَثَ اللَّهُ نَبِيًّا إِلَّا رَعَى الْغَنَمَ، قَالَ أَصْحَابُهُ: وَأَنْتَ؟ قَالَ: نَعَمْ، كُنْتُ أَرْعَاهَا عَلَى قَرَارِيطَ لِأَهْلِ مَكَّةَ',
          'urdu_translation': 'اللہ تعالیٰ نے کوئی نبی نہیں بھیجا مگر اس نے بکریاں چرائی ہوں؛ صحابہ کے سوال پر آپ ﷺ نے فرمایا: ہاں، میں بھی اہلِ مکہ کی بکریاں چند قیراط کے عوض چرایا کرتا تھا۔',
        },
        {
          'stable_id': 'ref_musnad_hilf',
          'source_stable_id': 'src_musnad_ahmad',
          'section_or_hadith_number': 'مسند عبد الرحمن بن عوف رضي الله عنه',
          'urdu_translation': 'رسول اللہ ﷺ نے بعثت کے بعد حلف الفضول کا ذکر فرمایا کہ میں عبداللہ بن جدعان کے گھر ایک ایسے معاہدے میں شریک تھا جس کے بدلے میں سرخ اونٹ بھی لینا پسند نہ کرتا۔',
        },
        {
          'stable_id': 'ref_ibn_hisham_khadijah',
          'source_stable_id': 'src_ibn_hisham',
          'section_or_hadith_number': 'خروجه ﷺ إلى الشام في مال خديجة وبناء الكعبة',
          'urdu_translation': 'سیدہ خدیجہ کے تجارتی مال کے ساتھ سفرِ شام، نکاحِ مبارک اور قریش کی جانب سے تعمیرِ کعبہ و تنصیبِ حجرِ اسود کا تذکرہ۔',
        },
        {
          'stable_id': 'ref_bukhari_kabah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب الحج — باب فضل مكة وبنيانها',
          'urdu_translation': 'قریش کی جانب سے کعبہ کی تعمیر میں حلال مال کم پڑنے پر حطیم کا حصہ عمارت سے باہر چھوڑ دینے کی صحیح روایت۔',
        },
        {
          'stable_id': 'ref_quran_alaq',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ العلق (96: 1–5)',
          'original_arabic_excerpt': 'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ ۝ خَلَقَ الْإِنسَانَ مِنْ عَلَقٍ',
          'urdu_translation': 'پڑھیے اپنے رب کے نام سے جس نے پیدا کیا، جس نے انسان کو جمے ہوئے خون سے پیدا فرمایا۔',
        },
        {
          'stable_id': 'ref_bukhari_wahy',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب بدء الوحي — حديث أم المؤمنين عائشة',
          'urdu_translation': 'غارِ حرا میں تحنّث، حضرت جبریل علیہ السلام کی آمد، سیدہ خدیجہ کی تسلّی اور ورقہ بن نوفل کی گواہی کی مفصل صحیح حدیث۔',
        },
        {
          'stable_id': 'ref_quran_shuara',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الشعراء (26: 214)',
          'original_arabic_excerpt': 'وَأَنذِرْ عَشِيرَتَكَ الْأَقْرَبِينَ',
          'urdu_translation': 'اور اپنے قریبی خاندان والوں کو ڈرائیے۔',
        },
        {
          'stable_id': 'ref_bukhari_safa',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب التفسير — باب وأنذر عشيرتك الأقربين',
          'urdu_translation': 'کوہِ صفا پر چڑھ کر قریش کے قبائل کو جمع فرمانے، دعوتِ توحید پیش کرنے اور ابو لہب کی مخالفت کی صحیح روایت۔',
        },
        {
          'stable_id': 'ref_ibn_hisham_habashah',
          'source_stable_id': 'src_ibn_hisham',
          'section_or_hadith_number': 'الهجرة الأولى والثانية إلى أرض الحبشة',
          'urdu_translation': 'مکہ میں مظالم کے بعد صحابۂ کرام کی حبشہ کی طرف ہجرت اور نجاشی کے دربار میں حضرت جعفر بن ابی طالب کا بیان۔',
        },
        {
          'stable_id': 'ref_ibn_sad_boycott',
          'source_stable_id': 'src_ibn_sad',
          'section_or_hadith_number': 'ذكر حصر قريش بني هاشم في الشعب ووفاة أبي طالب وخديجة',
          'urdu_translation': 'شعبِ ابی طالب میں بنی ہاشم و بنی المطلب کی تین سالہ محصوری اور نبوت کے دسویں سال ابو طالب و سیدہ خدیجہ کی وفات کا بیان۔',
        },
        {
          'stable_id': 'ref_bukhari_taif',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب بدء الخلق — حديث عائشة في يوم العقبة والطائف',
          'urdu_translation': 'طائف سے واپسی پر آپ ﷺ کی دعا و تکلیف اور ملک الجبال کی حاضری کے وقت اہلِ طائف کے لیے ہدایت کی امید کی صحیح روایت۔',
        },
        {
          'stable_id': 'ref_quran_isra',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الإسراء (17: 1)',
          'original_arabic_excerpt': 'سُبْحَانَ الَّذِي أَسْرَىٰ بِعَبْدِهِ لَيْلًا مِّنَ الْمَسْجِدِ الْحَرَامِ إِلَى الْمَسْجِدِ الْأَقْصَى',
          'urdu_translation': 'پاک ہے وہ ذات جو اپنے بندے کو رات کے ایک حصے میں مسجدِ حرام سے مسجدِ اقصیٰ تک لے گئی۔',
        },
        {
          'stable_id': 'ref_bukhari_aqabah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب مناقب الأنصار — باب وفود الأنصار وبيعة العقبة',
          'urdu_translation': 'موسمِ حج میں اہلِ یثرب سے ملاقات، بیعتِ عقبہ اولیٰ و ثانیہ اور حضرت مصعب بن عمیر کی مدینہ روانگی کا تذکرہ۔',
        },
        {
          'stable_id': 'ref_quran_tawbah_cave',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ التوبۃ (9: 40)',
          'original_arabic_excerpt': 'ثَانِيَ اثْنَيْنِ إِذْ هُمَا فِي الْغَارِ إِذْ يَقُولُ لِصَاحِبِهِ لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا',
          'urdu_translation': 'جب دونوں غار میں تھے اور آپ ﷺ اپنے ساتھی (حضرت ابوبکر) سے فرما رہے تھے کہ غم نہ کرو بے شک اللہ ہمارے ساتھ ہے۔',
        },
        {
          'stable_id': 'ref_bukhari_hijrah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب مناقب الأنصار — باب هجرة النبي ﷺ وأصحابه إلى المدينة',
          'urdu_translation': 'ہجرتِ مدینہ، غارِ ثور، سراقہ بن مالک کے تعاقب، قباء میں قیام اور اہلِ مدینہ کے والہانہ استقبال کی مفصل صحیح احادیث۔',
        },
        {
          'stable_id': 'ref_bukhari_masjid',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب مناقب الأنصار — باب بناء المسجد والمؤاخاة',
          'urdu_translation': 'مسجدِ نبوی ﷺ کی تعمیر اور مہاجرین و انصار کے درمیان مواخات کے قیام کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_ibn_hisham_sahifah',
          'source_stable_id': 'src_ibn_hisham',
          'section_or_hadith_number': 'كتاب النبي ﷺ بين المهاجرين والأنصار وموادعة يهود',
          'urdu_translation': 'مدینہ منورہ میں مہاجرین، انصار اور قبائلِ یہود کے باہمی حقوق و فرائض پر مشتمل آئینی دستاویز (میثاقِ مدینہ) کا متن۔',
        },
        {
          'stable_id': 'ref_quran_anfal_badr',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الأنفال (8: 7–12، 42)',
          'urdu_translation': 'غزوۂ بدر کے اسباب، تعداد کے فرق اور اہلِ ایمان کی غیبی نصرت کا قرآنی بیان۔',
        },
        {
          'stable_id': 'ref_bukhari_badr',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة بدر الكبرى',
          'urdu_translation': 'رمضان 2 ہجری میں بدر کے مقام پر معرکۂ حق و باطل اور اس کے نتائج کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_quran_ali_imran_uhud',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ آلِ عمران (3: 121–172)',
          'urdu_translation': 'غزوۂ اُحد کی تیاری، تیر اندازوں کے مورچے، آزمائش و ثباتِ قدم اور نتائج کا قرآنی تبصرہ۔',
        },
        {
          'stable_id': 'ref_bukhari_uhud',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة أحد',
          'urdu_translation': 'شوال 3 ہجری میں پیش آنے والے غزوۂ اُحد، شہادتِ حضرت حمزہ اور صحابۂ کرام کی استقامت کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_quran_ahzab',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الأحزاب (33: 9–27)',
          'urdu_translation': 'غزوۂ خندق (احزاب) میں محاصرۂ مدینہ، غیبی نصرت اور بنو قریظہ کے انجام کا قرآنی بیان۔',
        },
        {
          'stable_id': 'ref_bukhari_khandaq',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة الخندق وهي الأحزاب',
          'urdu_translation': '5 ہجری میں خندق کی کھدائی، اتحادی لشکروں کے محاصرے اور حضرت سعد بن معاذ کے فیصلے کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_quran_fath_hudaybiyyah',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ الفتح (48: 1، 18، 24)',
          'urdu_translation': 'بیعتِ رضوان اور صلحِ حدیبیہ کو فتحِ مبین قرار دیے جانے کا قرآنی تذکرہ۔',
        },
        {
          'stable_id': 'ref_bukhari_hudaybiyyah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب الشروط — باب الشروط في الجهاد والمصالحة',
          'urdu_translation': 'ذی القعدہ 6 ہجری میں صلحِ حدیبیہ کی شرائط، بیعتِ رضوان اور اس کے دور رس اثرات کی مفصل صحیح حدیث۔',
        },
        {
          'stable_id': 'ref_bukhari_letters',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب بدء الوحي وكتاب الجهاد — مکاتیبِ نبوی ﷺ بنامِ ملوک',
          'urdu_translation': 'صلحِ حدیبیہ کے بعد ہرقل (قیصرِ روم)، کسریٰ، مقوقس اور نجاشی سمیت سلاطین کو دعوتی خطوط کی ارسالگی کا بیان۔',
        },
        {
          'stable_id': 'ref_bukhari_khaybar',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة خيبر',
          'urdu_translation': '7 ہجری میں قلعہ بند خطۂ خیبر کی فتح اور حضرت علی رضی اللہ عنہ کے ہاتھوں پرچمِ فتح کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_bukhari_fath_makkah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة الفتح في رمضان',
          'urdu_translation': 'رمضان 8 ہجری میں مکہ مکرمہ کی پرامن فتح، بتوں کے خاتمے اور عام معافی کی صحیح احادیث۔',
        },
        {
          'stable_id': 'ref_quran_tawbah_hunayn_tabuk',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ التوبۃ (9: 25–26، 117–118)',
          'urdu_translation': 'غزوۂ حنین میں کثرتِ تعداد پر آزمائش اور غزوۂ تبوک (ساعۃ العسرۃ) کا قرآنی بیان۔',
        },
        {
          'stable_id': 'ref_muslim_hajj_wida',
          'source_stable_id': 'src_muslim',
          'section_or_hadith_number': 'كتاب الحج — باب حجة النبي ﷺ (حدیثِ جابر)',
          'original_arabic_excerpt': 'إِنَّ دِمَاءَكُمْ وَأَمْوَالَكُمْ حَرَامٌ عَلَيْكُمْ كَحُرْمَةِ يَوْمِكُمْ هَذَا فِي شَهْرِكُمْ هَذَا فِي بَلَدِكُمْ هَذَا',
          'urdu_translation': 'بے شک تمہارے خون اور تمہارے مال ایک دوسرے پر اسی طرح حرام ہیں جس طرح تمہارا یہ دن، یہ مہینہ اور یہ شہر حرمت والا ہے۔',
        },
        {
          'stable_id': 'ref_quran_maidah_ikmal',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ المائدۃ (5: 3)',
          'original_arabic_excerpt': 'الْيَوْمَ أَكْمَلْتُ لَكُمْ دِينَكُمْ وَأَتْمَمْتُ عَلَيْكُمْ نِعْمَتِي وَرَضِيتُ لَكُمُ الْإِسْلَامَ دِينًا',
          'urdu_translation': 'آج میں نے تمہارے لیے تمہارا دین مکمل کر دیا اور تم پر اپنی نعمت تمام کر دی اور تمہارے لیے اسلام کو بطورِ دین پسند فرمایا۔',
        },
        {
          'stable_id': 'ref_bukhari_wafat',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب مرض النبي ﷺ ووفاته',
          'urdu_translation': 'ربیع الاول 11 ہجری میں مرضِ وفات، حضرت ابوبکر صدیق کی امامت، وصالِ نبوی ﷺ اور مسجدِ نبوی میں تدفین کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_quran_nur_ifk',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ النور (24: 11–20)',
          'urdu_translation': 'واقعۂ افک میں ام المؤمنین سیدہ عائشہ صدیقہ رضی اللہ عنہا کی پاکدامنی و براءت اور افترا پردازی کی مذمت کا قرآنی فیصلہ۔',
        },
        {
          'stable_id': 'ref_bukhari_ifk_mustaliq',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب حديث الإفك وغزوة بني المصطلق',
          'urdu_translation': 'غزوۂ بنو المصطلق (المریسیع) کے موقع پر منافقین کی سازشوں اور ام المؤمنین سیدہ عائشہ رضی اللہ عنہا کی مفصل صحیح حدیث۔',
        },
        {
          'stable_id': 'ref_bukhari_mutah',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة مؤتة',
          'urdu_translation': 'جمادی الاولیٰ 8 ہجری میں رومی سرحد پر معرکۂ موتہ، تین امراء کی شہادت اور حضرت خالد بن ولید کی سیف اللہ کے لقب کے ساتھ واپسی۔',
        },
        {
          'stable_id': 'ref_bukhari_wufood',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب وفود العرب إلى النبي ﷺ',
          'urdu_translation': 'فتحِ مکہ کے بعد جزیرۂ عرب کے مختلف قبائل (بنو تمیم، بنو ثقیف، عبد القیس اور نجران وغیرہ) کے وفود کی مدینہ آمد۔',
        },
        {
          'stable_id': 'ref_quran_baqarah_riba_khamr',
          'source_stable_id': 'src_quran',
          'section_or_hadith_number': 'سورۃ البقرۃ (2: 275–279) و سورۃ المائدۃ (5: 90)',
          'urdu_translation': 'مدنی معاشرے میں شراب و جوئے کی مکمل حرمت اور سودی نظام کے قطعی خاتمے کے قرآنی احکام۔',
        },
        {
          'stable_id': 'ref_bukhari_azwaj_ahlbayt',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب فضائل أصحاب النبي ﷺ — مناقبِ اہلِ بیت و ازواج',
          'urdu_translation': 'ازواجِ مطہرات، سیدہ فاطمہ الزہراء، حضرت حسن و حسین اور صحابۂ کرام کے فضائل و مناقب کی صحیح احادیث۔',
        },
        {
          'stable_id': 'ref_bukhari_shamail',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المناقب وكتاب الأدب — باب صفة النبي ﷺ',
          'urdu_translation': 'رسول اللہ ﷺ کے حلیۂ مبارک، تبسم، سادگی، عبادت، امانت داری اور حسنِ اخلاق سے متعلق صحیح روایات۔',
        },
        {
          'stable_id': 'ref_muslim_rahmat_akhlaq',
          'source_stable_id': 'src_muslim',
          'section_or_hadith_number': 'كتاب الفضائل — باب في رحمته ﷺ وخلقه العظيم',
          'urdu_translation': 'قرآن کو آپ ﷺ کا خلق قرار دیے جانے، بچوں اور کمزوروں پر شفقت اور عفو و درگزر کی صحیح احادیث۔',
        },
        {
          'stable_id': 'ref_bukhari_zamzam',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المناقب — باب قصة زمزم',
          'urdu_translation': 'عبدالمطلب بن ہاشم کی طرف سے چاہِ زمزم کی بازیافت، دو سونے کے ہرن اور تلواروں کے برآمد ہونے کا تذکرہ۔',
        },
        {
          'stable_id': 'ref_muslim_shaqq_sadr',
          'source_stable_id': 'src_muslim',
          'section_or_hadith_number': 'كتاب الإيمان — باب الإسراء برسول الله ﷺ (حديث أنس)',
          'urdu_translation': 'بنی سعد میں بچپن کے دوران حضرت جبریل علیہ السلام کی آمد اور معجزۂ شقِ صدر کی صحیح مسلم کی روایت۔',
        },
        {
          'stable_id': 'ref_bukhari_umar_islam',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب فضائل أصحاب النبي ﷺ — مناقب عمر بن الخطاب',
          'urdu_translation': 'حضرت عمر بن خطاب رضی اللہ عنہ کے قبولِ اسلام کے بعد مکہ میں اہلِ ایمان کو حاصل ہونے والی عزت و علانیہ عبادت۔',
        },
        {
          'stable_id': 'ref_bukhari_qaynuqa_nadir',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — حديث إجلاء بني النضير وبني قينقاع',
          'urdu_translation': 'میثاقِ مدینہ کی عہد شکنی پر بنو قینقاع و بنو نضیر کی جلاوطنی اور سورۃ الحشر کے نزول کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_bukhari_bir_maunah_rajee',
          'source_stable_id': 'src_bukhari',
          'section_or_hadith_number': 'كتاب المغازي — باب غزوة الرجيع وبئر معونة',
          'urdu_translation': '4 ہجری میں واقعۂ رجیع (خبیب بن عدی) اور سانحۂ بئرِ معونہ (ستر قراء کی شہادت و قنوتِ نازلہ) کی صحیح روایات۔',
        },
        {
          'stable_id': 'ref_tirmidhi_shamail',
          'source_stable_id': 'src_tirmidhi',
          'section_or_hadith_number': 'الشمائل المحمدية — باب ما جاء في خلق رسول الله ﷺ',
          'urdu_translation': 'رسول اللہ ﷺ کے حلیۂ مبارک، مہرِ نبوت، اندازِ کلام، تبسم اور روزمرہ شمائل کی جامع روایات۔',
        },
      ]) {
      batch.insert('source_references', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  
    await batch.commit(noResult: true);
  }

  Future<void> _seedInitialResearchVersions(DatabaseExecutor txn) async {
    final existingVersions = await txn.query(
      'research_versions',
      columns: ['version_tag'],
    );
    final existingTags = existingVersions
        .map((v) => AppDatabase.readString(v['version_tag']))
        .toSet();

    if (!existingTags.contains('v1.0.0-phase3')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.0.0-phase3',
              'chapter_stable_id': 'chapter_001',
              'change_summary_urdu': 'ابتدائی دو ابواب کے مستند اردو متن، تحقیقی شواہد اور رنگوں کی درجہ بندی کی پہلی اشاعت۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v1.1.0-chapters-3-5')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.1.0-chapters-3-5',
              'chapter_stable_id': 'chapter_003',
              'change_summary_urdu': 'ابواب سوم تا پنجم (عہدِ شباب، حلف الفضول، نزولِ وحی، اعلانیہ دعوت اور ہجرتِ حبشہ) کا مع مآخذ و اسناد اضافہ۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v1.2.0-chapters-6-8')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.2.0-chapters-6-8',
              'chapter_stable_id': 'chapter_006',
              'change_summary_urdu': 'ابواب ششم تا ہشتم (سفرِ طائف، اسراء و معراج، بیعتِ عقبہ، ہجرتِ مدینہ، میثاقِ مدینہ اور غزوۂ بدر) کا تحقیقی اضافہ۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v1.3.0-chapters-9-12')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.3.0-chapters-9-12',
              'chapter_stable_id': 'chapter_009',
              'change_summary_urdu': 'ابواب نہم تا دوازدہم (اُحد، احزاب، صلحِ حدیبیہ، خیبر، فتحِ مکہ، حنین، تبوک، حجۃ الوداع اور وصالِ نبوی ﷺ) کی تکمیل۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v1.4.0-chapters-13-16')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.4.0-chapters-13-16',
              'chapter_stable_id': 'chapter_013',
              'change_summary_urdu': 'ابواب سیزدہم تا شانزدہم (بنو المصطلق، واقعۂ افک، غزوۂ موتہ، عام الوفود، اہلِ بیت و ازواجِ مطہرات، اور شمائل و اخلاقِ نبوی ﷺ) کی تکمیل۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v1.4.1-search-and-chronology')) {
      await txn.insert('research_versions', {
              'version_tag': 'v1.4.1-search-and-chronology',
              'change_summary_urdu': 'تمام ۱۶ ابواب کے لیے مکمل آف لائن تلاش، تاریخی نقشہ جات، اور زمانی خطِ سیر کی جامع توثیق و ہم آہنگی۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (!existingTags.contains('v2.0.0-encyclopedic-seerah')) {
      await txn.insert('research_versions', {
              'version_tag': 'v2.0.0-encyclopedic-seerah',
              'chapter_stable_id': 'chapter_001',
              'change_summary_urdu': 'تمام ۱۶ ابواب کی مکمل، تفصیلی اور مرحلہ وار توسیع: غزوات کی ابتدا تا انجام مکمل جنگی و تاریخی جزئیات، کبار صحابہ کے قبولِ اسلام و اولین ملاقات کے واقعات، اور شمائل، اخلاق، رضا، ناراضی، منہیات و اقوالِ نبوی ﷺ کا جامع بیان۔',
              'revised_by': 'Seerah Research Editorial Board',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedNarrationsAndLinks(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'nar_abu_qatadah',
          'name_arabic': 'أبو قتادة الأنصاري رضي الله عنه',
          'name_urdu': 'حضرت ابو قتادہ انصاری رضی اللہ عنہ',
          'death_hijri': 54,
          'scholarly_grading': 'صحابیِ رسول ﷺ',
          'biographical_note': 'جلیل القدر صحابی جن سے پیر کے دن روزے اور ولادتِ نبوی ﷺ سے متعلق صحیح مسلم کی حدیث مروی ہے۔',
        },
        {
          'stable_id': 'nar_urwah_ibn_zubayr',
          'name_arabic': 'عروة بن الزبير رحمه الله',
          'name_urdu': 'عروہ بن زبیر رحمہ اللہ',
          'death_hijri': 94,
          'scholarly_grading': 'ثقہ فقیہ تابعی و مآخذِ سیرت کے اولین راوی',
          'biographical_note': 'مدینہ منورہ کے کبار فقہا اور ابتدائی مغازی و سیرت کے مستند راویوں میں شمار ہوتے ہیں۔',
        },
        {
          'stable_id': 'nar_ibn_ishaq',
          'name_arabic': 'محمد بن إسحاق رحمه الله',
          'name_urdu': 'محمد بن اسحاق رحمہ اللہ',
          'death_hijri': 151,
          'scholarly_grading': 'امام المغازی والسیر (محدثین کے ہاں صدوق فی الحدیث، مستند فی المغازی)',
          'biographical_note': 'کلاسیکی سیرت نگاری کے سب سے نمایاں مؤلف، جن کی کتاب سیرت ابنِ ہشام کی بنیاد ہے۔',
        },
        {
          'stable_id': 'nar_aishah',
          'name_arabic': 'أم المؤمنين عائشة الصديقة رضي الله عنها',
          'name_urdu': 'ام المؤمنین سیدہ عائشہ صدیقہ رضی اللہ عنہا',
          'death_hijri': 58,
          'scholarly_grading': 'ام المؤمنین و مکثراتِ حدیث صحابیہ',
          'biographical_note': 'پہلی وحی کے آغاز اور تعمیرِ کعبہ سے متعلق صحیح بخاری کی بنیادی احادیث کی راویہ۔',
        },
        {
          'stable_id': 'nar_abu_hurairah',
          'name_arabic': 'أبو هريرة رضي الله عنه',
          'name_urdu': 'حضرت ابو ہریرہ رضی اللہ عنہ',
          'death_hijri': 59,
          'scholarly_grading': 'جلیل القدر صحابیِ رسول ﷺ',
          'biographical_note': 'عہدِ طفولیت و شباب میں انبیائے کرام اور رسول اللہ ﷺ کی گلہ بانی سے متعلق صحیح بخاری کی حدیث کے راوی۔',
        },
        {
          'stable_id': 'nar_ibn_abbas',
          'name_arabic': 'عبد الله بن عباس رضي الله عنهما',
          'name_urdu': 'حضرت عبداللہ بن عباس رضی اللہ عنہما',
          'death_hijri': 68,
          'scholarly_grading': 'حبر الامۃ و ترجمان القرآن صحابی',
          'biographical_note': 'کوہِ صفا پر اعلانیہ دعوتِ اسلام اور ابو لہب کے ردِعمل کی صحیح بخاری والی روایت کے راوی۔',
        },
        {
          'stable_id': 'nar_jabir',
          'name_arabic': 'جابر بن عبد الله الأنصاري رضي الله عنهما',
          'name_urdu': 'حضرت جابر بن عبداللہ انصاری رضی اللہ عنہما',
          'death_hijri': 78,
          'scholarly_grading': 'مکثر صحابیِ رسول ﷺ',
          'biographical_note': 'حجۃ الوداع کے پورے مناسک اور خطبۂ عرفات کی صحیح مسلم والی جامع حدیث کے راوی۔',
        },
      ]) {
      batch.insert('narrators', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'narr_muslim_monday_birth',
          'source_reference_stable_id': 'ref_muslim_monday',
          'matn_arabic': 'سُئِلَ عَنْ صَوْمِ يَوْمِ الِاثْنَيْنِ؟ قَالَ: ذَاكَ يَوْمٌ وُلِدْتُ فِيهِ، وَيَوْمٌ بُعِثْتُ أَوْ أُنْزِلَ عَلَيَّ فِيهِ',
          'urdu_summary': 'رسول اللہ ﷺ سے پیر کے دن کے روزے کے بارے میں دریافت کیا گیا تو آپ ﷺ نے فرمایا: یہی وہ دن ہے جس میں میری ولادت ہوئی اور اسی میں مجھ پر وحی نازل ہوئی۔',
          'isnad_chain_summary': 'امام مسلم ← محمد بن المثنى ← محمد بن جعفر ← شعبہ ← غیلان بن جریر ← عبداللہ بن معبد الزمانی ← حضرت ابو قتادہ رضی اللہ عنہ',
          'hadith_grade': 'صحیح (مسند متصل)',
          'historical_weight_note': 'حدیث کی صحت کے ساتھ ساتھ یہ روایت ولادتِ نبوی ﷺ کے دن (پیر) کے تعین میں قطعی تاریخی دلیل کی حیثیت رکھتی ہے۔',
          'tradition': 'sunni',
        },
        {
          'stable_id': 'narr_bukhari_thuwaybah',
          'source_reference_stable_id': 'ref_bukhari_thuwaybah',
          'matn_arabic': 'أَرْضَعَتْهُ ثُوَيْبَةُ مَوْلَاةُ أَبِي لَهَبٍ',
          'urdu_summary': 'حضرت ام حبیبہ رضی اللہ عنہا کی روایت میں عروہ بن زبیر کے طریق سے حضرت ثویبہ کی رضاعت کا ذکر ہے۔',
          'isnad_chain_summary': 'امام بخاری ← الحکم بن نافع ← شعیب ← الزہری ← عروہ بن زبیر',
          'hadith_grade': 'صحیح (حدیثی و تاریخی طور پر ثابت)',
          'historical_weight_note': 'محدثین اور مؤرخین دونوں کے نزدیک ابتدائی رضاعت کی مضبوط ترین شہادت۔',
          'tradition': 'sunni',
        },
        {
          'stable_id': 'narr_tabari_vow',
          'source_reference_stable_id': 'ref_tabari_vow',
          'matn_arabic': 'ذكر نذر عبد المطلب في ذبح أحد بنيه عند الكعبة',
          'urdu_summary': 'عبدالمطلب کی دس بیٹوں کی نذر اور سو اونٹوں کے فدیے سے متعلق تاریخی بیان۔',
          'isnad_chain_summary': 'ابنِ جریر طبری ← ابنِ حمید ← سلمہ ← محمد بن اسحاق (بعض اسنادی کڑیوں میں انقطاع)',
          'hadith_grade': 'تاریخی روایت (حدیثی معیار پر سنداً کلام موجود ہے)',
          'historical_weight_note': 'شہرت کے باوجود اس کے بعض تفصیلی اجزاء کو قطعی تاریخی حقیقت کے بجائے مختلف فیہ درجے میں رکھا گیا ہے۔',
          'tradition': 'classical_history',
        },
        {
          'stable_id': 'narr_bukhari_shepherd',
          'source_reference_stable_id': 'ref_bukhari_shepherd',
          'matn_arabic': 'مَا بَعَثَ اللَّهُ نَبِيًّا إِلَّا رَعَى الْغَنَمَ، قَالَ أَصْحَابُهُ: وَأَنْتَ؟ قَالَ: نَعَمْ، كُنْتُ أَرْعَاهَا عَلَى قَرَارِيطَ لِأَهْلِ مَكَّةَ',
          'urdu_summary': 'حضرت ابو ہریرہ رضی اللہ عنہ سے مروی ہے کہ رسول اللہ ﷺ نے اہلِ مکہ کی بکریاں چند قیراط اجرت پر چرانے کی صراحت فرمائی۔',
          'isnad_chain_summary': 'امام بخاری ← احمد بن محمد المکی ← عمرو بن یحییٰ ← جدّہ سعید بن عمرو ← حضرت ابو ہریرہ رضی اللہ عنہ',
          'hadith_grade': 'صحیح (مسند متصل)',
          'historical_weight_note': 'بعثت سے قبل محنت کشی اور سادگی کی زندگی پر مضبوط ترین حدیثی شہادت۔',
          'tradition': 'sunni',
        },
        {
          'stable_id': 'narr_bukhari_wahy',
          'source_reference_stable_id': 'ref_bukhari_wahy',
          'matn_arabic': 'أَوَّلُ مَا بُدِئَ بِهِ رَسُولُ اللَّهِ ﷺ مِنَ الْوَحْيِ الرُّؤْيَا الصَّالِحَةُ فِي النَّوْمِ، ثُمَّ حُبِّبَ إِلَيْهِ الْخَلَاءُ، وَكَانَ يَخْلُو بِغَارِ حِرَاءٍ',
          'urdu_summary': 'ام المؤمنین سیدہ عائشہ رضی اللہ عنہا سے غارِ حرا، پہلی وحی، سیدہ خدیجہ اور ورقہ بن نوفل کی گواہی کا مفصل بیان۔',
          'isnad_chain_summary': 'امام بخاری ← یحییٰ بن بکیر ← اللیث ← عقیل ← ابنِ شہاب زہری ← عروہ بن زبیر ← ام المؤمنین عائشہ رضی اللہ عنہا',
          'hadith_grade': 'صحیح (متفق علیہ)',
          'historical_weight_note': 'نزولِ وحی کے آغاز کے لیے سیرتِ نبوی ﷺ کی سب سے بنیادی اور قطعی دستاویز۔',
          'tradition': 'sunni',
        },
        {
          'stable_id': 'narr_bukhari_safa',
          'source_reference_stable_id': 'ref_bukhari_safa',
          'matn_arabic': 'لَمَّا نَزَلَتْ: وَأَنْذِرْ عَشِيرَتَكَ الْأَقْرَبِينَ صَعِدَ النَّبِيُّ ﷺ عَلَى الصَّفَا فَجَعَلَ يُنَادِي يَا بَنِي فِهْرٍ يَا بَنِي عَدِيٍّ',
          'urdu_summary': 'حضرت ابنِ عباس رضی اللہ عنہما سے کوہِ صفا پر اعلانیہ دعوت اور ابو لہب کی مخالفت کی روایت۔',
          'isnad_chain_summary': 'امام بخاری ← عمر بن حفص ← ابی ← الاعمش ← عمرو بن مرہ ← سعید بن جبیر ← حضرت ابنِ عباس رضی اللہ عنہما',
          'hadith_grade': 'صحیح (متفق علیہ)',
          'historical_weight_note': 'خفیہ دعوت سے اعلانیہ دعوت کی طرف منتقلی کی مستند ترین شہادت۔',
          'tradition': 'sunni',
        },
        {
          'stable_id': 'narr_muslim_hajj_wida',
          'source_reference_stable_id': 'ref_muslim_hajj_wida',
          'matn_arabic': 'إِنَّ دِمَاءَكُمْ وَأَمْوَالَكُمْ حَرَامٌ عَلَيْكُمْ كَحُرْمَةِ يَوْمِكُمْ هَذَا فِي شَهْرِكُمْ هَذَا فِي بَلَدِكُمْ هَذَا',
          'urdu_summary': 'حضرت جابر بن عبداللہ رضی اللہ عنہما سے مروی حجۃ الوداع کی جامع حدیث جس میں میدانِ عرفات کے تاریخی خطبے کے بنیادی انسانی حقوق مذکور ہیں۔',
          'isnad_chain_summary': 'امام مسلم ← ابو بکر بن ابی شیبہ و اسحاق ← حاتم بن اسماعیل ← جعفر بن محمد ← والد محمد الباقر ← حضرت جابر بن عبداللہ رضی اللہ عنہما',
          'hadith_grade': 'صحیح (مسند متصل)',
          'historical_weight_note': 'حجۃ الوداع اور خطبۂ عرفات کی سب سے مفصل اور مستند ترین حدیثی دستاویز۔',
          'tradition': 'sunni',
        },
      ]) {
      batch.insert('narrations', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  
    await batch.commit(noResult: true);

    final existingLinks = await txn.query(
      'narration_narrators',
      columns: ['narration_stable_id', 'narrator_stable_id'],
    );
    final existingPairs = existingLinks
        .map(
          (e) =>
              "${AppDatabase.readString(e['narration_stable_id'])}:${AppDatabase.readString(e['narrator_stable_id'])}",
        )
        .toSet();

    final desiredLinks = <Map<String, Object?>>[
      if (!existingPairs.contains('narr_muslim_monday_birth:nar_abu_qatadah'))
        {
          'narration_stable_id': 'narr_muslim_monday_birth',
          'narrator_stable_id': 'nar_abu_qatadah',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_bukhari_thuwaybah:nar_urwah_ibn_zubayr'))
        {
          'narration_stable_id': 'narr_bukhari_thuwaybah',
          'narrator_stable_id': 'nar_urwah_ibn_zubayr',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_tabari_vow:nar_ibn_ishaq'))
        {
          'narration_stable_id': 'narr_tabari_vow',
          'narrator_stable_id': 'nar_ibn_ishaq',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_bukhari_shepherd:nar_abu_hurairah'))
        {
          'narration_stable_id': 'narr_bukhari_shepherd',
          'narrator_stable_id': 'nar_abu_hurairah',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_bukhari_wahy:nar_aishah'))
        {
          'narration_stable_id': 'narr_bukhari_wahy',
          'narrator_stable_id': 'nar_aishah',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_bukhari_safa:nar_ibn_abbas'))
        {
          'narration_stable_id': 'narr_bukhari_safa',
          'narrator_stable_id': 'nar_ibn_abbas',
          'chain_position': 1,
        },
      if (!existingPairs.contains('narr_muslim_hajj_wida:nar_jabir'))
        {
          'narration_stable_id': 'narr_muslim_hajj_wida',
          'narrator_stable_id': 'nar_jabir',
          'chain_position': 1,
        },
    ];

    if (desiredLinks.isNotEmpty) {
      final batch = txn.batch();
      for (final row in desiredLinks) {
        batch.insert('narration_narrators', row);
      }
    
      await batch.commit(noResult: true);
    }

    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch2_c_01',
      sourceRefId: 'ref_muslim_monday',
      narrationId: 'narr_muslim_monday_birth',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch2_c_03',
      sourceRefId: 'ref_bukhari_thuwaybah',
      narrationId: 'narr_bukhari_thuwaybah',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch1_c_07',
      sourceRefId: 'ref_tabari_vow',
      narrationId: 'narr_tabari_vow',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch3_c_01',
      sourceRefId: 'ref_bukhari_shepherd',
      narrationId: 'narr_bukhari_shepherd',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch4_c_01',
      sourceRefId: 'ref_bukhari_wahy',
      narrationId: 'narr_bukhari_wahy',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch4_c_03',
      sourceRefId: 'ref_bukhari_wahy',
      narrationId: 'narr_bukhari_wahy',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch5_c_02',
      sourceRefId: 'ref_bukhari_safa',
      narrationId: 'narr_bukhari_safa',
    );
    await _linkClaimEvidenceToNarration(
      txn: txn,
      claimId: 'ch12_c_01',
      sourceRefId: 'ref_muslim_hajj_wida',
      narrationId: 'narr_muslim_hajj_wida',
    );
  }

  Future<void> _linkClaimEvidenceToNarration({
    required DatabaseExecutor txn,
    required String claimId,
    required String sourceRefId,
    required String narrationId,
  }) async {
    await txn.update(
      'claim_evidence',
      {'narration_stable_id': narrationId},
      where: 'claim_stable_id = ? AND source_reference_stable_id = ?',
      whereArgs: [claimId, sourceRefId],
    );
  }

  Future<void> _seedTimelineLocationsAndCrossRefs(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'loc_makkah',
          'name_arabic': 'مكة المكرمة',
          'name_urdu': 'مکہ مکرمہ',
          'region_urdu': 'حجاز',
          'latitude': 21.4225,
          'longitude': 39.8262,
          'historical_significance_urdu': 'بیت اللہ کی مرکزیت، قریش کا مسکن، ولادتِ نبوی ﷺ اور بعثت کا مقام۔',
        },
        {
          'stable_id': 'loc_madinah',
          'name_arabic': 'المدينة المنورة (يثرب)',
          'name_urdu': 'مدینہ منورہ (یثرب)',
          'region_urdu': 'حجاز',
          'latitude': 24.4672,
          'longitude': 39.6111,
          'historical_significance_urdu': 'حضرت عبداللہ کی وفات کا مقام، بنو نجار کا وطن، اور بعد ازاں ہجرتِ نبوی ﷺ کا مرکز۔',
        },
        {
          'stable_id': 'loc_abwa',
          'name_arabic': 'الأبواء',
          'name_urdu': 'ابواء',
          'region_urdu': 'مکہ اور مدینہ کے درمیان',
          'latitude': 23.1000,
          'longitude': 39.0833,
          'historical_significance_urdu': 'مکہ و مدینہ کے راستے میں واقع مقام جہاں والدہ ماجدہ سیدہ آمنہ کی رحلت و تدفین ہوئی۔',
        },
        {
          'stable_id': 'loc_banu_sad',
          'name_arabic': 'ديار بني سعد (قرب الطائف)',
          'name_urdu': 'دیارِ بنی سعد (قربِ طائف)',
          'region_urdu': 'مشرقی حجاز',
          'latitude': 20.7500,
          'longitude': 41.0500,
          'historical_significance_urdu': 'سیدہ حلیمہ سعدیہ رضی اللہ عنہا کا مسکن جہاں رسول اللہ ﷺ کا ابتدائی بچپن گزرا۔',
        },
        {
          'stable_id': 'loc_yemen_sanaa',
          'name_arabic': 'صنعاء (اليمن)',
          'name_urdu': 'صنعاء (یمن)',
          'region_urdu': 'جنوبی عرب',
          'latitude': 15.3694,
          'longitude': 44.1910,
          'historical_significance_urdu': 'یمن کا مرکزی شہر جہاں سے ابرہہ نے خانہ کعبہ کی طرف لشکر کشی کی۔',
        },
        {
          'stable_id': 'loc_sham_busra',
          'name_arabic': 'الشام (طريق التجارة)',
          'name_urdu': 'ملکِ شام (تجارتی راستہ)',
          'region_urdu': 'شمالی عرب',
          'latitude': 32.5177,
          'longitude': 36.4819,
          'historical_significance_urdu': 'قریش کا معروف گرمائی تجارتی راستہ (رحلۃ الصیف) جہاں حضرت عبداللہ اور بعد میں رسول اللہ ﷺ تجارت کے لیے تشریف لے گئے۔',
        },
        {
          'stable_id': 'loc_habashah',
          'name_arabic': 'أرض الحبشة (أكسوم)',
          'name_urdu': 'ملکِ حبشہ (اکسوم)',
          'region_urdu': 'بحیرۂ احمر کے پار (مشرقی افریقہ)',
          'latitude': 14.1211,
          'longitude': 38.7234,
          'historical_significance_urdu': 'نبوت کے پانچویں سال صحابۂ کرام کی پہلی اور دوسری ہجرت کی پناہ گاہ جہاں عادل حکمران نجاشی نے مسلمانوں کو امن فراہم کیا۔',
        },
        {
          'stable_id': 'loc_taif',
          'name_arabic': 'الطائف',
          'name_urdu': 'طائف',
          'region_urdu': 'حجاز (مکہ کے جنوب مشرق)',
          'latitude': 21.2854,
          'longitude': 40.4262,
          'historical_significance_urdu': 'بنو ثقیف کا شہر جہاں نبوت کے دسویں سال رسول اللہ ﷺ نے دعوتِ اسلام کے لیے سفر فرمایا۔',
        },
        {
          'stable_id': 'loc_jerusalem',
          'name_arabic': 'بيت المقدس (المسجد الأقصى)',
          'name_urdu': 'بیت المقدس (مسجدِ اقصیٰ)',
          'region_urdu': 'فلسطین / بلادِ شام',
          'latitude': 31.7780,
          'longitude': 35.2354,
          'historical_significance_urdu': 'سفرِ اسراء کی منزل اور مدینہ منورہ میں تحویلِ قبلہ سے قبل مسلمانوں کا پہلا قبلہ۔',
        },
        {
          'stable_id': 'loc_badr',
          'name_arabic': 'بدر',
          'name_urdu': 'بدر',
          'region_urdu': 'مدینہ منورہ کے جنوب مغرب',
          'latitude': 23.7810,
          'longitude': 38.7916,
          'historical_significance_urdu': 'رمضان 2 ہجری میں اسلامی تاریخ کے پہلے فیصلہ کن معرکے (غزوۂ بدرِ کبریٰ) کا مقام۔',
        },
        {
          'stable_id': 'loc_hudaybiyyah',
          'name_arabic': 'الحديبية',
          'name_urdu': 'حدیبیہ',
          'region_urdu': 'مکہ مکرمہ کے مغرب میں',
          'latitude': 21.5500,
          'longitude': 39.0500,
          'historical_significance_urdu': '6 ہجری میں بیعتِ رضوان اور صلحِ حدیبیہ (فتحِ مبین) کا تاریخی مقام۔',
        },
        {
          'stable_id': 'loc_khaybar',
          'name_arabic': 'خيبر',
          'name_urdu': 'خیبر',
          'region_urdu': 'مدینہ منورہ کے شمال میں',
          'latitude': 25.6986,
          'longitude': 39.2933,
          'historical_significance_urdu': '7 ہجری میں فتح ہونے والا مضبوط قلعہ بند نخلستان اور تجارتی مرکز۔',
        },
        {
          'stable_id': 'loc_hunayn',
          'name_arabic': 'حنين',
          'name_urdu': 'حنین',
          'region_urdu': 'مکہ اور طائف کے درمیان وادی',
          'latitude': 21.8500,
          'longitude': 40.3500,
          'historical_significance_urdu': 'شوال 8 ہجری میں فتحِ مکہ کے بعد ہوازن و ثقیف کے ساتھ غزوۂ حنین کا مقام۔',
        },
        {
          'stable_id': 'loc_tabuk',
          'name_arabic': 'تبوك',
          'name_urdu': 'تبوک',
          'region_urdu': 'شمالی حجاز (سرحدِ شام)',
          'latitude': 28.3835,
          'longitude': 36.5662,
          'historical_significance_urdu': 'رجب 9 ہجری میں رومی خطرات کے پیشِ نظر جیشِ عسرۃ کی آخری بڑی مہم کا مقام۔',
        },
        {
          'stable_id': 'loc_mutah',
          'name_arabic': 'مؤتة',
          'name_urdu': 'موتہ (بلادِ شام)',
          'region_urdu': 'جنوبی اردن / سرحدِ شام',
          'latitude': 31.0600,
          'longitude': 35.7000,
          'historical_significance_urdu': 'جمادی الاولیٰ 8 ہجری میں رومی و غسانی لشکر کے ساتھ تاریخی معرکۂ موتہ کا مقام۔',
        },
        {
          'stable_id': 'loc_najran',
          'name_arabic': 'نجران',
          'name_urdu': 'نجران',
          'region_urdu': 'جنوبی عرب (سرحدِ یمن)',
          'latitude': 17.4924,
          'longitude': 44.1277,
          'historical_significance_urdu': 'عام الوفود میں مدینہ حاضر ہونے والے نجران کے معروف وفد اور معاہدۂ امن کا علاقہ۔',
        },
      ]) {
      batch.insert('historical_locations', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'tl_001_abdullah_journey',
          'chapter_stable_id': 'chapter_001',
          'claim_stable_id': 'ch1_c_06',
          'gregorian_year': 570,
          'era_code': 'pre_prophethood',
          'order_index': 1,
          'title_urdu': 'حضرت عبداللہ کا سفرِ شام اور یثرب میں رحلت',
          'summary_urdu': 'سیدہ آمنہ سے نکاح کے بعد حضرت عبداللہ تجارتی قافلے کے ساتھ شام گئے اور واپسی پر مدینہ (یثرب) میں وفات پا گئے۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_002_aam_ul_feel',
          'chapter_stable_id': 'chapter_001',
          'claim_stable_id': 'ch1_c_08',
          'gregorian_year': 570,
          'era_code': 'pre_prophethood',
          'order_index': 2,
          'title_urdu': 'واقعۂ فیل اور حرمِ مکہ کی حفاظت',
          'summary_urdu': 'یمن کے حکمران ابرہہ کی مکہ پر لشکر کشی اور اللہ تعالیٰ کی جانب سے خانہ کعبہ کی حفاظت، جو سورۃ الفیل میں مذکور ہے۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_003_birth',
          'chapter_stable_id': 'chapter_002',
          'claim_stable_id': 'ch2_c_01',
          'gregorian_year': 570,
          'era_code': 'childhood',
          'order_index': 3,
          'title_urdu': 'مکہ مکرمہ میں ولادتِ باسعادت ﷺ',
          'summary_urdu': 'عام الفیل میں پیر کے روز مکہ مکرمہ میں رسول اللہ ﷺ کی ولادت ہوئی؛ تاریخِ ربیع الاول کے تعین میں مؤرخین کے متعدد اقوال ہیں۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_004_banu_sad',
          'chapter_stable_id': 'chapter_002',
          'claim_stable_id': 'ch2_c_04',
          'gregorian_year': 571,
          'era_code': 'childhood',
          'order_index': 4,
          'title_urdu': 'قبیلۂ بنی سعد میں سیدہ حلیمہ سعدیہ کے ہاں رضاعت',
          'summary_urdu': 'ابتدائی ایام میں حضرت ثویبہ کے بعد خالص عربی ماحول میں پرورش کے لیے آپ ﷺ کو دیارِ بنی سعد بھیجا گیا۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_005_abwa',
          'chapter_stable_id': 'chapter_002',
          'claim_stable_id': 'ch2_c_06',
          'gregorian_year': 576,
          'era_code': 'childhood',
          'order_index': 5,
          'title_urdu': 'سفرِ مدینہ اور مقامِ ابواء پر والدہ کی وفات',
          'summary_urdu': 'تقریباً چھ برس کی عمر میں والدہ محترمہ سیدہ آمنہ مدینہ کی زیارت سے واپسی پر ابواء میں انتقال فرما گئیں۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_006_kafalat',
          'chapter_stable_id': 'chapter_002',
          'claim_stable_id': 'ch2_c_07',
          'gregorian_year': 578,
          'era_code': 'childhood',
          'order_index': 6,
          'title_urdu': 'دادا عبدالمطلب کی رحلت اور ابو طالب کی کفالت',
          'summary_urdu': 'آٹھ برس کی عمر میں عبدالمطلب کے انتقال کے بعد چچا ابو طالب نے رسول اللہ ﷺ کی کفالت و سرپرستی سنبھالی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_007_hilf_fudul',
          'chapter_stable_id': 'chapter_003',
          'claim_stable_id': 'ch3_c_04',
          'gregorian_year': 590,
          'era_code': 'pre_prophethood',
          'order_index': 7,
          'title_urdu': 'حلف الفضول کا تاریخی معاہدۂ نصرت',
          'summary_urdu': 'حربِ فجار کے بعد مکہ میں مظلوموں کی حمایت اور حق رسی کے لیے عبداللہ بن جدعان کے گھر معاہدہ طے پایا جس میں آپ ﷺ شریک تھے۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_008_nikah_khadijah',
          'chapter_stable_id': 'chapter_003',
          'claim_stable_id': 'ch3_c_05',
          'gregorian_year': 595,
          'era_code': 'pre_prophethood',
          'order_index': 8,
          'title_urdu': 'تجارتِ شام اور سیدہ خدیجہ رضی اللہ عنہا سے نکاحِ مبارک',
          'summary_urdu': 'پچیس برس کی عمر میں سیدہ خدیجہ کے تجارتی قافلے کے کامیاب سفرِ شام کے بعد نکاحِ مبارک انجام پایا۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_009_rebuilding_kabah',
          'chapter_stable_id': 'chapter_003',
          'claim_stable_id': 'ch3_c_08',
          'gregorian_year': 605,
          'era_code': 'pre_prophethood',
          'order_index': 9,
          'title_urdu': 'تعمیرِ کعبہ اور حجرِ اسود کی تنصیب کا فیصلہ',
          'summary_urdu': 'پینتیس برس کی عمر میں قریش نے خانہ کعبہ کی تعمیرِ نو کی اور آپ ﷺ نے حجرِ اسود کے تنازع کا حکیمانہ فیصلہ فرمایا۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_010_first_revelation',
          'chapter_stable_id': 'chapter_004',
          'claim_stable_id': 'ch4_c_02',
          'gregorian_year': 610,
          'era_code': 'early_makkan',
          'order_index': 10,
          'title_urdu': 'غارِ حرا میں پہلی وحی کا نزول اور بعثتِ نبوی ﷺ',
          'summary_urdu': 'چالیس برس کی عمر میں غارِ حرا میں حضرت جبریل علیہ السلام سورۃ العلق کی ابتدائی آیات لے کر نازل ہوئے۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_011_open_dawah',
          'chapter_stable_id': 'chapter_005',
          'claim_stable_id': 'ch5_c_02',
          'gregorian_year': 613,
          'era_code': 'early_makkan',
          'order_index': 11,
          'title_urdu': 'کوہِ صفا سے اعلانیہ دعوتِ اسلام کا آغاز',
          'summary_urdu': 'تین سالہ خفیہ دعوت کے بعد وَأَنذِرْ عَشِيرَتَكَ الْأَقْرَبِينَ کے حکم پر آپ ﷺ نے کوہِ صفا سے قریش کو علانیہ دعوت دی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_012_habashah',
          'chapter_stable_id': 'chapter_005',
          'claim_stable_id': 'ch5_c_04',
          'gregorian_year': 615,
          'era_code': 'early_makkan',
          'order_index': 12,
          'title_urdu': 'عادل حکمران نجاشی کے ملک حبشہ کی طرف ہجرت',
          'summary_urdu': 'قریش کے بڑھتے ہوئے مظالم کے سبب نبوت کے پانچویں سال صحابۂ کرام نے حبشہ کی جانب ہجرت کی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_013_shib_boycott',
          'chapter_stable_id': 'chapter_005',
          'claim_stable_id': 'ch5_c_06',
          'gregorian_year': 617,
          'era_code': 'early_makkan',
          'order_index': 13,
          'title_urdu': 'شعبِ ابی طالب کا بائیکاٹ اور عام الحزن',
          'summary_urdu': 'تین سالہ معاشی و معاشرتی مقاطعے کے بعد نبوت کے دسویں سال ابو طالب اور سیدہ خدیجہ رضی اللہ عنہا کی رحلت ہوئی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_014_taif',
          'chapter_stable_id': 'chapter_006',
          'claim_stable_id': 'ch6_c_01',
          'gregorian_year': 619,
          'era_code': 'late_makkan',
          'order_index': 14,
          'title_urdu': 'دعوتِ اسلام کے لیے طائف کا سفر',
          'summary_urdu': 'عام الحزن کے بعد رسول اللہ ﷺ طائف تشریف لے گئے اور شدید ایذا رسانی کے باوجود اہلِ طائف کی ہدایت کی دعا فرمائی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_015_isra_miraj',
          'chapter_stable_id': 'chapter_006',
          'claim_stable_id': 'ch6_c_02',
          'gregorian_year': 620,
          'era_code': 'late_makkan',
          'order_index': 15,
          'title_urdu': 'اسراء و معراج اور فرضیتِ نماز',
          'summary_urdu': 'مسجدِ حرام سے مسجدِ اقصیٰ اور آسمانوں کا بابرکت سفر جس میں پنجگانہ نمازوں کی فرضیت عطا ہوئی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_016_aqabah',
          'chapter_stable_id': 'chapter_006',
          'claim_stable_id': 'ch6_c_04',
          'gregorian_year': 622,
          'era_code': 'late_makkan',
          'order_index': 16,
          'title_urdu': 'بیعتِ عقبہ ثانیہ اور انصار کی نصرت کا عہد',
          'summary_urdu': 'منیٰ میں عقبہ کے مقام پر مدینہ کے تہتر مرد اور دو خواتین نے رسول اللہ ﷺ کی حفاظت و نصرت پر بیعت کی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_017_hijrah',
          'chapter_stable_id': 'chapter_007',
          'claim_stable_id': 'ch7_c_01',
          'hijri_year': 1,
          'gregorian_year': 622,
          'era_code': 'hijrah_madinan',
          'order_index': 17,
          'title_urdu': 'غارِ ثور اور مدینہ منورہ کی طرف ہجرتِ نبوی ﷺ',
          'summary_urdu': 'حضرت ابوبکر صدیق رضی اللہ عنہ کی رفاقت میں غارِ ثور میں قیام، قباء میں مسجد کی تاسیس اور مدینہ آمد۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_018_masjid_mithaq',
          'chapter_stable_id': 'chapter_008',
          'claim_stable_id': 'ch8_c_02',
          'hijri_year': 1,
          'gregorian_year': 622,
          'era_code': 'hijrah_madinan',
          'order_index': 18,
          'title_urdu': 'مسجدِ نبوی، مواخات اور میثاقِ مدینہ کا قیام',
          'summary_urdu': 'مدینہ میں مہاجرین و انصار کے درمیان بھائی چارے اور تمام قبائل کے مابین آئینی معاہدے کی تدوین۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_019_badr',
          'chapter_stable_id': 'chapter_008',
          'claim_stable_id': 'ch8_c_04',
          'hijri_year': 2,
          'gregorian_year': 624,
          'era_code': 'hijrah_madinan',
          'order_index': 19,
          'title_urdu': 'غزوۂ بدرِ کبریٰ میں تاریخی فتح',
          'summary_urdu': 'رمضان 2 ہجری میں بدر کے مقام پر حق و باطل کا پہلا بڑا معرکہ جس میں اہلِ ایمان کو فتح نصیب ہوئی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_020_uhud',
          'chapter_stable_id': 'chapter_009',
          'claim_stable_id': 'ch9_c_01',
          'hijri_year': 3,
          'gregorian_year': 625,
          'era_code': 'madinan_era',
          'order_index': 20,
          'title_urdu': 'غزوۂ اُحد اور صبر و ثبات کی آزمائش',
          'summary_urdu': 'شوال 3 ہجری میں جبلِ اُحد کے دامن میں قریش سے معرکہ جس میں حضرت حمزہ سمیت ستر صحابہ شہید ہوئے۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_021_khandaq',
          'chapter_stable_id': 'chapter_009',
          'claim_stable_id': 'ch9_c_02',
          'hijri_year': 5,
          'gregorian_year': 627,
          'era_code': 'madinan_era',
          'order_index': 21,
          'title_urdu': 'غزوۂ خندق (احزاب) اور بنو قریظہ کا فیصلہ',
          'summary_urdu': 'شوال 5 ہجری میں دس ہزار کے اتحادی لشکر کا خندق کے ذریعے دفاع اور غداری پر بنو قریظہ کے خلاف تحکیمِ سعد۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_022_hudaybiyyah',
          'chapter_stable_id': 'chapter_010',
          'claim_stable_id': 'ch10_c_01',
          'hijri_year': 6,
          'gregorian_year': 628,
          'era_code': 'madinan_era',
          'order_index': 22,
          'title_urdu': 'بیعتِ رضوان اور صلحِ حدیبیہ (فتحِ مبین)',
          'summary_urdu': 'ذی القعدہ 6 ہجری میں قریش کے ساتھ دس سالہ امن معاہدہ اور ملوکِ عالم کو دعوتی خطوط کا آغاز۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_023_khaybar',
          'chapter_stable_id': 'chapter_010',
          'claim_stable_id': 'ch10_c_04',
          'hijri_year': 7,
          'gregorian_year': 628,
          'era_code': 'madinan_era',
          'order_index': 23,
          'title_urdu': 'غزوۂ خیبر کی فتح',
          'summary_urdu': 'محرم 7 ہجری میں حضرت علی رضی اللہ عنہ کے ہاتھوں خیبر کے مضبوط قلعوں کی فتح۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_024_fath_makkah',
          'chapter_stable_id': 'chapter_011',
          'claim_stable_id': 'ch11_c_01',
          'hijri_year': 8,
          'gregorian_year': 630,
          'era_code': 'madinan_era',
          'order_index': 24,
          'title_urdu': 'فتحِ مکہ اور عام معافی کا اعلان',
          'summary_urdu': 'رمضان 8 ہجری میں دس ہزار صحابہ کے ہمراہ مکہ مکرمہ کی پرامن فتح، بتوں کا خاتمہ اور عفوِ عام۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_025_hunayn_tabuk',
          'chapter_stable_id': 'chapter_011',
          'claim_stable_id': 'ch11_c_02',
          'hijri_year': 9,
          'gregorian_year': 630,
          'era_code': 'madinan_era',
          'order_index': 25,
          'title_urdu': 'غزوۂ حنین، طائف اور غزوۂ تبوک',
          'summary_urdu': 'شوال 8 ہجری میں حنین کی فتح کے بعد رجب 9 ہجری میں تیس ہزار کے لشکر کے ساتھ تبوک کا تاریخی سفر۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_026_hijjatul_wida',
          'chapter_stable_id': 'chapter_012',
          'claim_stable_id': 'ch12_c_01',
          'hijri_year': 10,
          'gregorian_year': 632,
          'era_code': 'madinan_era',
          'order_index': 26,
          'title_urdu': 'حجۃ الوداع اور آیتِ تکمیلِ دین کا نزول',
          'summary_urdu': 'ذی الحجہ 10 ہجری میں عرفات کے میدان میں ایک لاکھ سے زائد صحابہ کے سامنے عالمگیر انسانی حقوق کا خطبہ۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_027_wafat',
          'chapter_stable_id': 'chapter_012',
          'claim_stable_id': 'ch12_c_03',
          'hijri_year': 11,
          'gregorian_year': 632,
          'era_code': 'madinan_era',
          'order_index': 27,
          'title_urdu': 'وصالِ نبوی ﷺ (رفیقِ اعلیٰ سے ملاقات)',
          'summary_urdu': 'ربیع الاول 11 ہجری میں پیر کے روز مدینہ منورہ میں حجرۂ عائشہ رضی اللہ عنہا میں وصالِ مبارک۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_028_banu_mustaliq_ifk',
          'chapter_stable_id': 'chapter_013',
          'claim_stable_id': 'ch13_c_03',
          'hijri_year': 6,
          'gregorian_year': 627,
          'era_code': 'madinan_era',
          'order_index': 28,
          'title_urdu': 'بنو المصطلق اور سورۃ النور میں براءتِ عائشہ رضی اللہ عنہا',
          'summary_urdu': 'غزوۂ بنو المصطلق سے واپسی پر منافقین کی بہتان تراشی اور اللہ تعالیٰ کی جانب سے ام المؤمنین سیدہ عائشہ کی قرآنی براءت۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_029_mutah',
          'chapter_stable_id': 'chapter_013',
          'claim_stable_id': 'ch13_c_04',
          'hijri_year': 8,
          'gregorian_year': 629,
          'era_code': 'madinan_era',
          'order_index': 29,
          'title_urdu': 'معرکۂ موتہ اور تین امراء کی شہادت',
          'summary_urdu': 'رومی سرحد پر زید بن حارثہ، جعفر طیار اور عبداللہ بن رواحہ کی شہادت اور خالد بن ولید کی واپسی۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
        {
          'stable_id': 'tl_030_wufood',
          'chapter_stable_id': 'chapter_014',
          'claim_stable_id': 'ch14_c_01',
          'hijri_year': 9,
          'gregorian_year': 630,
          'era_code': 'madinan_era',
          'order_index': 30,
          'title_urdu': 'عام الوفود: جزیرۂ عرب کے قبائل کی مدینہ آمد',
          'summary_urdu': 'فتحِ مکہ کے بعد بنو تمیم، بنو ثقیف، عبد القیس اور نجران سمیت درجنوں قبائل کے وفود کی آمد اور قبولِ اسلام۔',
          'reliability_status': ReliabilityStatus.confirmed.storageValue,
        },
      ]) {
      batch.insert('timeline_events', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  
    await batch.commit(noResult: true);

    final existingEventLocations = await txn.query(
      'event_locations',
      columns: ['timeline_event_stable_id', 'location_stable_id'],
    );
    final existingElPairs = existingEventLocations
        .map(
          (e) =>
              "${AppDatabase.readString(e['timeline_event_stable_id'])}:${AppDatabase.readString(e['location_stable_id'])}",
        )
        .toSet();

    final desiredEventLocations = <Map<String, Object?>>[
      if (!existingElPairs.contains('tl_001_abdullah_journey:loc_sham_busra'))
        {
          'timeline_event_stable_id': 'tl_001_abdullah_journey',
          'location_stable_id': 'loc_sham_busra',
        },
      if (!existingElPairs.contains('tl_001_abdullah_journey:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_001_abdullah_journey',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_002_aam_ul_feel:loc_yemen_sanaa'))
        {
          'timeline_event_stable_id': 'tl_002_aam_ul_feel',
          'location_stable_id': 'loc_yemen_sanaa',
        },
      if (!existingElPairs.contains('tl_002_aam_ul_feel:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_002_aam_ul_feel',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_003_birth:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_003_birth',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_004_banu_sad:loc_banu_sad'))
        {
          'timeline_event_stable_id': 'tl_004_banu_sad',
          'location_stable_id': 'loc_banu_sad',
        },
      if (!existingElPairs.contains('tl_005_abwa:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_005_abwa',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_005_abwa:loc_abwa'))
        {
          'timeline_event_stable_id': 'tl_005_abwa',
          'location_stable_id': 'loc_abwa',
        },
      if (!existingElPairs.contains('tl_006_kafalat:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_006_kafalat',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_007_hilf_fudul:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_007_hilf_fudul',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_008_nikah_khadijah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_008_nikah_khadijah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_008_nikah_khadijah:loc_sham_busra'))
        {
          'timeline_event_stable_id': 'tl_008_nikah_khadijah',
          'location_stable_id': 'loc_sham_busra',
        },
      if (!existingElPairs.contains('tl_009_rebuilding_kabah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_009_rebuilding_kabah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_010_first_revelation:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_010_first_revelation',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_011_open_dawah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_011_open_dawah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_012_habashah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_012_habashah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_012_habashah:loc_habashah'))
        {
          'timeline_event_stable_id': 'tl_012_habashah',
          'location_stable_id': 'loc_habashah',
        },
      if (!existingElPairs.contains('tl_013_shib_boycott:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_013_shib_boycott',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_014_taif:loc_taif'))
        {
          'timeline_event_stable_id': 'tl_014_taif',
          'location_stable_id': 'loc_taif',
        },
      if (!existingElPairs.contains('tl_015_isra_miraj:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_015_isra_miraj',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_015_isra_miraj:loc_jerusalem'))
        {
          'timeline_event_stable_id': 'tl_015_isra_miraj',
          'location_stable_id': 'loc_jerusalem',
        },
      if (!existingElPairs.contains('tl_016_aqabah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_016_aqabah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_017_hijrah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_017_hijrah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_017_hijrah:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_017_hijrah',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_018_masjid_mithaq:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_018_masjid_mithaq',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_019_badr:loc_badr'))
        {
          'timeline_event_stable_id': 'tl_019_badr',
          'location_stable_id': 'loc_badr',
        },
      if (!existingElPairs.contains('tl_020_uhud:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_020_uhud',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_021_khandaq:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_021_khandaq',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_022_hudaybiyyah:loc_hudaybiyyah'))
        {
          'timeline_event_stable_id': 'tl_022_hudaybiyyah',
          'location_stable_id': 'loc_hudaybiyyah',
        },
      if (!existingElPairs.contains('tl_023_khaybar:loc_khaybar'))
        {
          'timeline_event_stable_id': 'tl_023_khaybar',
          'location_stable_id': 'loc_khaybar',
        },
      if (!existingElPairs.contains('tl_024_fath_makkah:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_024_fath_makkah',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_025_hunayn_tabuk:loc_hunayn'))
        {
          'timeline_event_stable_id': 'tl_025_hunayn_tabuk',
          'location_stable_id': 'loc_hunayn',
        },
      if (!existingElPairs.contains('tl_025_hunayn_tabuk:loc_tabuk'))
        {
          'timeline_event_stable_id': 'tl_025_hunayn_tabuk',
          'location_stable_id': 'loc_tabuk',
        },
      if (!existingElPairs.contains('tl_026_hijjatul_wida:loc_makkah'))
        {
          'timeline_event_stable_id': 'tl_026_hijjatul_wida',
          'location_stable_id': 'loc_makkah',
        },
      if (!existingElPairs.contains('tl_027_wafat:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_027_wafat',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_028_banu_mustaliq_ifk:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_028_banu_mustaliq_ifk',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_029_mutah:loc_mutah'))
        {
          'timeline_event_stable_id': 'tl_029_mutah',
          'location_stable_id': 'loc_mutah',
        },
      if (!existingElPairs.contains('tl_030_wufood:loc_madinah'))
        {
          'timeline_event_stable_id': 'tl_030_wufood',
          'location_stable_id': 'loc_madinah',
        },
      if (!existingElPairs.contains('tl_030_wufood:loc_najran'))
        {
          'timeline_event_stable_id': 'tl_030_wufood',
          'location_stable_id': 'loc_najran',
        },
    ];

    if (desiredEventLocations.isNotEmpty) {
      final batch = txn.batch();
      for (final row in desiredEventLocations) {
        batch.insert('event_locations', row);
      }
    
      await batch.commit(noResult: true);
    }

    final existingCrossRefs = await txn.query(
      'event_cross_references',
      columns: ['source_entity_id', 'target_entity_id'],
    );
    final existingRefPairs = existingCrossRefs
        .map(
          (e) =>
              "${AppDatabase.readString(e['source_entity_id'])}:${AppDatabase.readString(e['target_entity_id'])}",
        )
        .toSet();

    final desiredCrossRefs = <Map<String, Object?>>[
      if (!existingRefPairs.contains('tl_001_abdullah_journey:tl_005_abwa'))
        {
          'source_entity_id': 'tl_001_abdullah_journey',
          'target_entity_id': 'tl_005_abwa',
          'target_type': 'timeline_event',
          'relation_type': 'background',
          'description_urdu': 'سیدہ آمنہ کا چھ برس بعد مدینہ جانا حضرت عبداللہ کے مدفون مقام اور ننھیال بنو نجار سے اسی تعلق کا تسلسل تھا۔',
        },
      if (!existingRefPairs.contains('tl_002_aam_ul_feel:tl_003_birth'))
        {
          'source_entity_id': 'tl_002_aam_ul_feel',
          'target_entity_id': 'tl_003_birth',
          'target_type': 'timeline_event',
          'relation_type': 'chronological_anchor',
          'description_urdu': 'عام الفیل عربوں کے ہاں ولادتِ نبوی ﷺ کا بنیادی تاریخی پیمانہ قرار پایا۔',
        },
      if (!existingRefPairs.contains('tl_005_abwa:tl_006_kafalat'))
        {
          'source_entity_id': 'tl_005_abwa',
          'target_entity_id': 'tl_006_kafalat',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'والدہ کی وفات کے بعد کفالت کی ذمہ داری براہِ راست دادا عبدالمطلب اور پھر ابو طالب کو منتقل ہوئی۔',
        },
      if (!existingRefPairs.contains('ch1_c_06:ch2_c_06'))
        {
          'source_entity_id': 'ch1_c_06',
          'target_entity_id': 'ch2_c_06',
          'target_type': 'claim',
          'relation_type': 'connected_family_event',
          'description_urdu': 'یثرب میں والد کی وفات اور ابواء میں والدہ کی رحلت نے عہدِ طفولیت میں یتیمی کے حالات مرتب کیے۔',
        },
      if (!existingRefPairs.contains('tl_010_first_revelation:tl_011_open_dawah'))
        {
          'source_entity_id': 'tl_010_first_revelation',
          'target_entity_id': 'tl_011_open_dawah',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'غارِ حرا میں پہلی وحی اور تین سالہ خفیہ دعوت کے بعد کوہِ صفا سے اعلانیہ دعوت کا مرحلہ شروع ہوا۔',
        },
      if (!existingRefPairs.contains('tl_011_open_dawah:tl_012_habashah'))
        {
          'source_entity_id': 'tl_011_open_dawah',
          'target_entity_id': 'tl_012_habashah',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'اعلانیہ دعوت کے بعد قریش کے مظالم بڑھے تو صحابۂ کرام کو حبشہ کی طرف ہجرت کی اجازت ملی۔',
        },
      if (!existingRefPairs.contains('tl_016_aqabah:tl_017_hijrah'))
        {
          'source_entity_id': 'tl_016_aqabah',
          'target_entity_id': 'tl_017_hijrah',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'بیعتِ عقبہ ثانیہ میں انصار کے عہدِ نصرت نے مدینہ منورہ کی طرف ہجرتِ نبوی ﷺ کا محفوظ راستہ ہموار کیا۔',
        },
      if (!existingRefPairs.contains('tl_017_hijrah:tl_018_masjid_mithaq'))
        {
          'source_entity_id': 'tl_017_hijrah',
          'target_entity_id': 'tl_018_masjid_mithaq',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'ہجرتِ مدینہ کے فوراً بعد مسجدِ نبوی ﷺ کی تعمیر، مواخات اور میثاقِ مدینہ کے ذریعے نئے معاشرے کی بنیاد رکھی گئی۔',
        },
      if (!existingRefPairs.contains('tl_022_hudaybiyyah:tl_024_fath_makkah'))
        {
          'source_entity_id': 'tl_022_hudaybiyyah',
          'target_entity_id': 'tl_024_fath_makkah',
          'target_type': 'timeline_event',
          'relation_type': 'consequence',
          'description_urdu': 'صلحِ حدیبیہ کے بعد اشاعتِ اسلام کی تیز رفتار توسیع اور قریش کی عہد شکنی نے فتحِ مکہ کا راستہ ہموار کیا۔',
        },
      if (!existingRefPairs.contains('tl_026_hijjatul_wida:tl_027_wafat'))
        {
          'source_entity_id': 'tl_026_hijjatul_wida',
          'target_entity_id': 'tl_027_wafat',
          'target_type': 'timeline_event',
          'relation_type': 'chronological_anchor',
          'description_urdu': 'حجۃ الوداع میں تکمیلِ دین کے اعلان کے تقریباً تین ماہ بعد ربیع الاول 11 ہجری میں وصالِ نبوی ﷺ واقع ہوا۔',
        },
    ];

    if (desiredCrossRefs.isNotEmpty) {
      final batch = txn.batch();
      for (final row in desiredCrossRefs) {
        batch.insert('event_cross_references', row);
      }
    
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedNarrationsAndPronunciation(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'narr_yaqubi_birth_date',
          'source_reference_stable_id': 'ref_yaqubi_birth_date',
          'matn_arabic': 'ذكر اختلاف الأقوال في يوم وشهر ولادة النبي ﷺ',
          'urdu_summary': 'تاریخِ یعقوبی میں ولادتِ مبارکہ کے دن اور ماہِ ربیع الاول کی مختلف روایات و اقوال کا تقابلی ذکر موجود ہے۔',
          'isnad_chain_summary': 'مؤرخ احمد بن ابی یعقوب اليعقوبي کی تاریخی جمع و تدوین',
          'hadith_grade': 'تاریخی بیان (بغیر متصل سند)',
          'historical_weight_note': 'شیعہ و کلاسیکی تاریخ کی اس روایت سے واضح ہوتا ہے کہ تاریخِ ولادت کے دقیق عدد پر قدیم مؤرخین میں اختلاف رہا ہے۔',
          'tradition': 'shia',
        },
      ]) {
      batch.insert('narrations', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in <Map<String, Object?>>[
        {
          'stable_id': 'pron_quraysh',
          'term_arabic': 'قُرَيْش',
          'term_urdu': 'قریش',
          'transliteration': 'Quraysh',
          'phonetic_guide': 'قُ + رَیْش',
          'urdu_explanation': 'قاف پر پیش (ضَمّہ)، را پر زبر (فَتحہ) اور یا ساکن؛ عربی میں قُریش پڑھا جاتا ہے۔',
        },
        {
          'stable_id': 'pron_abdul_muttalib',
          'term_arabic': 'عَبْدُ الْمُطَّلِب',
          'term_urdu': 'عبدالمطلب',
          'transliteration': 'Abdul-Muttalib',
          'phonetic_guide': 'عَبْ + دُلْ + مُطْ + طَ + لِب',
          'urdu_explanation': 'میم پر پیش، طا مشدّد پر زبر اور لام کے نیچے زیر (کسرہ) ہے؛ طا کو کھینچ کر نہیں بلکہ مشدّد ادا کریں۔',
        },
        {
          'stable_id': 'pron_aminah',
          'term_arabic': 'آمِنَةُ بِنْتُ وَهْب',
          'term_urdu': 'آمنہ بنتِ وہب',
          'transliteration': 'Aminah bint Wahb',
          'phonetic_guide': 'آ + مِ + نَہ — بِنْ + تُ — وَہْب',
          'urdu_explanation': 'میم کے نیچے زیر (آمِنہ) ہے؛ "وَہْب" میں ہا ساکن اور با پر جزم ہے (وہاب نہیں)۔',
        },
        {
          'stable_id': 'pron_thuwaybah',
          'term_arabic': 'ثُوَيْبَة',
          'term_urdu': 'ثویبہ',
          'transliteration': 'Thuwaybah',
          'phonetic_guide': 'ثُ + وَیْ + بَہ',
          'urdu_explanation': 'ثا پر پیش اور واؤ پر زبر کے ساتھ یا ساکن؛ نرمی سے ثُوَيْبَہ ادا کیا جاتا ہے۔',
        },
        {
          'stable_id': 'pron_halimah',
          'term_arabic': 'حَلِيمَةُ السَّعْدِيَّة',
          'term_urdu': 'حلیمہ سعدیہ',
          'transliteration': 'Halimah al-Sa‘diyyah',
          'phonetic_guide': 'حَ + لِی + مَہ — اَسْ + سَعْ + دِیَّہ',
          'urdu_explanation': 'حا پر زبر اور لام کے نیچے زیر؛ سعدیہ میں عین ساکن اور یا مشدّد ہے۔',
        },
        {
          'stable_id': 'pron_abwa',
          'term_arabic': 'الْأَبْوَاء',
          'term_urdu': 'ابواء',
          'transliteration': 'al-Abwa’',
          'phonetic_guide': 'اَبْ + وَا',
          'urdu_explanation': 'الف پر زبر اور با ساکن، واؤ کے بعد مد اور ہمزہ (ابواء)۔ مکہ و مدینہ کے درمیان معروف مقام۔',
        },
        {
          'stable_id': 'pron_yathrib',
          'term_arabic': 'يَثْرِب',
          'term_urdu': 'یثرب',
          'transliteration': 'Yathrib',
          'phonetic_guide': 'یَثْ + رِب',
          'urdu_explanation': 'یا پر زبر، ثا ساکن اور را کے نیچے زیر؛ مدینہ منورہ کا قبل از ہجرت قدیم نام۔',
        },
        {
          'stable_id': 'pron_banu_hashim',
          'term_arabic': 'بَنُو هَاشِم',
          'term_urdu': 'بنو ہاشم',
          'transliteration': 'Banu Hashim',
          'phonetic_guide': 'بَ + نُو — ہَا + شِم',
          'urdu_explanation': 'با پر زبر اور نون پر پیش کے ساتھ واؤ مدّہ؛ شین کے نیچے زیر (ہاشِم)۔',
        },
        {
          'stable_id': 'pron_hilf_fudul',
          'term_arabic': 'حِلْفُ الْفُضُول',
          'term_urdu': 'حلف الفضول',
          'transliteration': 'Hilf al-Fudul',
          'phonetic_guide': 'حِلْ + فُلْ + فُ + ضُول',
          'urdu_explanation': 'حا کے نیچے زیر (حِلف) یعنی عہد و پیمان، اور فا و ضاد پر پیش (فُضُول)۔',
        },
        {
          'stable_id': 'pron_ghar_hira',
          'term_arabic': 'غَارُ حِرَاء',
          'term_urdu': 'غارِ حرا',
          'transliteration': 'Ghar Hira’',
          'phonetic_guide': 'غَا + رُ — حِ + رَاء',
          'urdu_explanation': 'حِراء میں حا کے نیچے زیر اور را پر زبر کے بعد الف و ہمزہ ہے؛ جبلِ نور پر واقع غار۔',
        },
        {
          'stable_id': 'pron_khadijah',
          'term_arabic': 'خَدِيجَةُ بِنْتُ خُوَيْلِد',
          'term_urdu': 'خدیجہ بنتِ خویلد',
          'transliteration': 'Khadijah bint Khuwaylid',
          'phonetic_guide': 'خَ + دِی + جَہ — بِنْ + تُ — خُ + وَیْ + لِد',
          'urdu_explanation': 'خُوَیْلِد میں خا پر پیش، واؤ پر زبر، یا ساکن اور لام کے نیچے زیر ہے۔',
        },
        {
          'stable_id': 'pron_waraqah',
          'term_arabic': 'وَرَقَةُ بْنُ نَوْفَل',
          'term_urdu': 'ورقہ بن نوفل',
          'transliteration': 'Waraqah ibn Nawfal',
          'phonetic_guide': 'وَ + رَ + قَہ — اِبْ + نُ — نَوْ + فَل',
          'urdu_explanation': 'واؤ، را اور قاف تینوں پر زبر (وَرَقَہ) ہے؛ نَوْفَل میں نون پر زبر اور واؤ ساکن ہے۔',
        },
        {
          'stable_id': 'pron_habashah',
          'term_arabic': 'الْحَبَشَة',
          'term_urdu': 'حبشہ',
          'transliteration': 'al-Habashah',
          'phonetic_guide': 'حَ + بَ + شَہ',
          'urdu_explanation': 'حا، با اور شین تینوں پر زبر ہے (حَبَشَہ)؛ موجودہ ایتھوپیا و اریٹیریا کا تاریخی خطہ۔',
        },
        {
          'stable_id': 'pron_najashi',
          'term_arabic': 'النَّجَاشِي',
          'term_urdu': 'نجاشی',
          'transliteration': 'al-Najashi',
          'phonetic_guide': 'اَنْ + نَ + جَا + شِی',
          'urdu_explanation': 'نون پر زبر اور جیم کے بعد الف مدّہ؛ حبشہ کے بادشاہوں کا تاریخی لقب۔',
        },
        {
          'stable_id': 'pron_shib_abi_talib',
          'term_arabic': 'شِعْبُ أَبِي طَالِب',
          'term_urdu': 'شعبِ ابی طالب',
          'transliteration': 'Shi‘b Abi Talib',
          'phonetic_guide': 'شِعْ + بُ — اَ + بِی — طَا + لِب',
          'urdu_explanation': 'شِعْب میں شین کے نیچے زیر اور عین ساکن ہے، جس کے معنی پہاڑوں کے درمیانی گھاٹی کے ہیں۔',
        },
        {
          'stable_id': 'pron_taif',
          'term_arabic': 'الطَّائِف',
          'term_urdu': 'طائف',
          'transliteration': 'al-Ta’if',
          'phonetic_guide': 'اَطْ + طَا + اِف',
          'urdu_explanation': 'طا مشدّد پر زبر کے بعد الف اور ہمزہ کے نیچے زیر (طائِف) پڑھا جاتا ہے۔',
        },
        {
          'stable_id': 'pron_aqabah',
          'term_arabic': 'الْعَقَبَة',
          'term_urdu': 'عقبہ',
          'transliteration': 'al-‘Aqabah',
          'phonetic_guide': 'عَ + قَ + بَہ',
          'urdu_explanation': 'عین، قاف اور با تینوں پر زبر ہے (عَقَبَہ)؛ منیٰ کے قریب واقع گھاٹی جہاں بیعتِ عقبہ ہوئی۔',
        },
        {
          'stable_id': 'pron_ghar_thawr',
          'term_arabic': 'غَارُ ثَوْر',
          'term_urdu': 'غارِ ثور',
          'transliteration': 'Ghar Thawr',
          'phonetic_guide': 'غَا + رُ — ثَوْر',
          'urdu_explanation': 'ثَوْر میں ثا پر زبر اور واؤ ساکن ہے (ثَوْر)، جہاں ہجرت کے وقت تین راتیں قیام فرمایا گیا۔',
        },
        {
          'stable_id': 'pron_quba',
          'term_arabic': 'قُبَاء',
          'term_urdu': 'قباء',
          'transliteration': 'Quba’',
          'phonetic_guide': 'قُ + بَاء',
          'urdu_explanation': 'قاف پر پیش اور با پر زبر کے بعد الف و ہمزہ (قُباء)؛ مدینہ کے قریب پہلی مسجد کا مقام۔',
        },
        {
          'stable_id': 'pron_muakhat',
          'term_arabic': 'الْمُؤَاخَاة',
          'term_urdu': 'مواخات',
          'transliteration': 'al-Mu’akhat',
          'phonetic_guide': 'مُ + آ + خَات',
          'urdu_explanation': 'میم پر پیش اور ہمزہ پر زبر کے ساتھ الف مدّہ (مُوَاخَات)، جس کے معنی بھائی چارہ قائم کرنے کے ہیں۔',
        },
        {
          'stable_id': 'pron_badr',
          'term_arabic': 'بَدْر',
          'term_urdu': 'بدر',
          'transliteration': 'Badr',
          'phonetic_guide': 'بَدْر',
          'urdu_explanation': 'با پر زبر اور دال ساکن (بَدْر)؛ مدینہ کے جنوب مغرب میں واقع تاریخی مقام۔',
        },
        {
          'stable_id': 'pron_uhud',
          'term_arabic': 'أُحُد',
          'term_urdu': 'اُحد',
          'transliteration': 'Uhud',
          'phonetic_guide': 'اُ + حُد',
          'urdu_explanation': 'الف اور حا دونوں پر پیش (اُحُد) ہے؛ مدینہ منورہ کے شمال میں واقع مشہور پہاڑ۔',
        },
        {
          'stable_id': 'pron_khandaq',
          'term_arabic': 'الْخَنْدَق',
          'term_urdu': 'خندق',
          'transliteration': 'al-Khandaq',
          'phonetic_guide': 'خَنْ + دَق',
          'urdu_explanation': 'خا اور دال دونوں پر زبر، نون ساکن (خَنْدَق)؛ مدینہ کے دفاع کے لیے کھودی گئی گہری کھائی۔',
        },
        {
          'stable_id': 'pron_hudaybiyyah',
          'term_arabic': 'الْحُدَيْبِيَة',
          'term_urdu': 'حدیبیہ',
          'transliteration': 'al-Hudaybiyyah',
          'phonetic_guide': 'حُ + دَیْ + بِ + یَہ',
          'urdu_explanation': 'حا پر پیش، دال پر زبر، یا ساکن اور با کے نیچے زیر (حُدَیْبِیَہ)؛ مکہ کے قریب صلح کا تاریخی مقام۔',
        },
        {
          'stable_id': 'pron_khaybar',
          'term_arabic': 'خَيْبَر',
          'term_urdu': 'خیبر',
          'transliteration': 'Khaybar',
          'phonetic_guide': 'خَیْ + بَر',
          'urdu_explanation': 'خا اور با پر زبر، یا ساکن (خَیْبَر)؛ مدینہ کے شمال میں قلعہ بند خطہ۔',
        },
        {
          'stable_id': 'pron_hunayn',
          'term_arabic': 'حُنَيْن',
          'term_urdu': 'حنین',
          'transliteration': 'Hunayn',
          'phonetic_guide': 'حُ + نَیْن',
          'urdu_explanation': 'حا پر پیش اور نون پر زبر کے بعد یا ساکن (حُنَیْن)؛ مکہ و طائف کے درمیان وادی۔',
        },
        {
          'stable_id': 'pron_tabuk',
          'term_arabic': 'تَبُوك',
          'term_urdu': 'تبوک',
          'transliteration': 'Tabuk',
          'phonetic_guide': 'تَ + بُوک',
          'urdu_explanation': 'تا پر زبر اور با پر پیش کے ساتھ واؤ مدّہ (تَبُوک)؛ شمالی حجاز کا تاریخی شہر۔',
        },
        {
          'stable_id': 'pron_arafat',
          'term_arabic': 'عَرَفَات',
          'term_urdu': 'عرفات',
          'transliteration': '‘Arafat',
          'phonetic_guide': 'عَ + رَ + فَات',
          'urdu_explanation': 'عین اور را دونوں پر زبر اور فا کے بعد الف (عَرَفَات)؛ حج کے رکنِ اعظم وقوف کا میدان۔',
        },
        {
          'stable_id': 'pron_hijjatul_wida',
          'term_arabic': 'حَجَّةُ الْوَدَاع',
          'term_urdu': 'حجۃ الوداع',
          'transliteration': 'Hajjat al-Wada‘',
          'phonetic_guide': 'حَجْ + جَ + تُلْ — وَ + دَاع',
          'urdu_explanation': 'حا پر زبر اور جیم مشدّد؛ وَدَاع میں واؤ پر زبر (وَدَاع) یعنی الوداعی حج۔',
        },
        {
          'stable_id': 'pron_ifk',
          'term_arabic': 'الإِفْك',
          'term_urdu': 'افک',
          'transliteration': 'al-Ifk',
          'phonetic_guide': 'اِفْک',
          'urdu_explanation': 'الف کے نیچے زیر اور فا ساکن (اِفْک)؛ یعنی جھوٹا بہتان اور افترا۔',
        },
        {
          'stable_id': 'pron_mutah',
          'term_arabic': 'مُؤْتَة',
          'term_urdu': 'موتہ',
          'transliteration': 'Mu’tah',
          'phonetic_guide': 'مُؤْ + تَہ',
          'urdu_explanation': 'میم پر پیش اور ہمزہ ساکن (مُؤْتَہ)؛ جنوبی شام (اردن) کا معروف تاریخی مقام۔',
        },
        {
          'stable_id': 'pron_najran',
          'term_arabic': 'نَجْرَان',
          'term_urdu': 'نجران',
          'transliteration': 'Najran',
          'phonetic_guide': 'نَجْ + رَان',
          'urdu_explanation': 'نون پر زبر، جیم ساکن اور را کے بعد الف (نَجْرَان)؛ جنوبی عرب کا تاریخی خطہ۔',
        },
        {
          'stable_id': 'pron_shamail',
          'term_arabic': 'الشَّمَائِل',
          'term_urdu': 'شمائل',
          'transliteration': 'al-Shama’il',
          'phonetic_guide': 'شَ + مَا + اِل',
          'urdu_explanation': 'شین اور میم پر زبر، الف مدّہ اور ہمزہ کے نیچے زیر (شَمَائِل)؛ عادات و حلیہ مبارک۔',
        },
        {
          'stable_id': 'pron_ahl_ul_bayt',
          'term_arabic': 'أَهْلُ الْبَيْت',
          'term_urdu': 'اہلِ بیت',
          'transliteration': 'Ahl al-Bayt',
          'phonetic_guide': 'اَہْ + لُلْ — بَیْت',
          'urdu_explanation': 'با پر زبر اور یا ساکن (بَیْت)؛ نبی کریم ﷺ کا معزز خانوادہ اور ازواج و آل۔',
        },
        {
          'stable_id': 'pron_suffah',
          'term_arabic': 'الصُّفَّة',
          'term_urdu': 'صفہ',
          'transliteration': 'al-Suffah',
          'phonetic_guide': 'اَصْ + صُفْ + فَہ',
          'urdu_explanation': 'صاد پر پیش اور فا مشدّد پر زبر (صُفَّہ)؛ مسجدِ نبوی کا سایہ دار چبوترہ۔',
        },
      ]) {
      batch.insert('pronunciation_entries', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  
    await batch.commit(noResult: true);
  }

  Future<void> _seedSupportedLanguages(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final row in <Map<String, Object?>>[
        {
          'code': 'ur',
          'name_native': 'اردو',
          'name_english': 'Urdu',
          'direction': 'rtl',
          'is_active': 1,
        },
        {
          'code': 'ps',
          'name_native': 'پښتو',
          'name_english': 'Pashto',
          'direction': 'rtl',
          'is_active': 1,
        },
        {
          'code': 'ar',
          'name_native': 'العربية',
          'name_english': 'Arabic',
          'direction': 'rtl',
          'is_active': 1,
        },
        {
          'code': 'fa',
          'name_native': 'فارسی',
          'name_english': 'Persian',
          'direction': 'rtl',
          'is_active': 1,
        },
        {
          'code': 'en',
          'name_native': 'English',
          'name_english': 'English',
          'direction': 'ltr',
          'is_active': 1,
        },
      ]) {
      batch.insert('languages', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  
    await batch.commit(noResult: true);
  }

  Future<void> _seedPashtoChapterTranslations(DatabaseExecutor txn) async {
    final batch = txn.batch();
    for (final chapter in allChapterSeeds) {
      batch.insert(
        'chapter_translations',
        {
          'chapter_stable_id': chapter.stableId,
          'language_code': 'ps',
          'title': chapter.titlePashto,
          'subtitle': chapter.subtitlePashto,
          'era_label': chapter.eraLabelPashto,
          'summary': chapter.summaryPashto,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }
}
