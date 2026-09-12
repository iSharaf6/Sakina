import type { AppRole, GuidanceItem, ScholarProfile } from '../types'

const blankInsight = (id: string, status: GuidanceItem['insight']['status'] = 'draft') => ({
  id: `insight-${id}`,
  scholarId: 'demo-scholar',
  bodyAr: '',
  bodyEn: '',
  references: [],
  status,
  translationStatus: 'not_started' as const,
  revisionNumber: 1,
  updatedAt: null,
})

const currentPublishedInsight = (id: string) => ({
  ...blankInsight(id, 'published'),
  bodyAr: 'معاينة منشورة للتطوير المحلي فقط.',
  bodyEn: 'Development-only published preview.',
  translationStatus: 'reviewed' as const,
})

const marriageWorking = blankInsight('marriage-problems')
const worryWorking = {
  ...blankInsight('worry', 'submitted'),
  bodyAr: 'إرسال بديل تجريبي للتطوير المحلي فقط.',
  bodyEn: 'Development-only replacement submission.',
  translationStatus: 'reviewed' as const,
}
const worryPublished = currentPublishedInsight('worry-current')
const bereavementWorking = blankInsight('bereavement', 'submitted')
const givingUpPublished = currentPublishedInsight('giving-up-current')
const betrayedWorking = blankInsight('betrayed')
const hardshipWorking = blankInsight('hardship')
const mockedWorking = blankInsight('mocked')

export const demoItems: GuidanceItem[] = [
  {
    id: 'marriage-problems-4-35',
    situationId: 'marriageProblems',
    titleEn: "When you’re having marriage problems",
    titleAr: 'عندما تواجه مشكلات زوجية',
    verseKey: '4:35',
    surahNameEn: 'An-Nisa',
    surahNameAr: 'النساء',
    ayahAr:
      'وَإِنْ خِفْتُمْ شِقَاقَ بَيْنِهِمَا فَٱبْعَثُوا۟ حَكَمًا مِّنْ أَهْلِهِۦ وَحَكَمًا مِّنْ أَهْلِهَآ إِن يُرِيدَآ إِصْلَـٰحًا يُوَفِّقِ ٱللَّهُ بَيْنَهُمَآ ۗ إِنَّ ٱللَّهَ كَانَ عَلِيمًا خَبِيرًا',
    meaningEn:
      'If you fear a breach between the two, appoint an arbitrator from his family and an arbitrator from her family.',
    orientationEn:
      'The ayah gives a process for serious marital rift: a trustworthy arbitrator from each family and a sincere effort toward repair. Mediation is not appropriate where there is danger or coercion; safety and qualified support come first.',
    orientationAr:
      'تضع الآية مسارًا عند الشقاق الزوجي الشديد: حَكَمًا موثوقًا من كل أسرة، ومحاولة صادقة للإصلاح. ولا تكون الوساطة مناسبة عند وجود خطر أو إكراه؛ فالسلامة والاستعانة بجهة مؤهلة أولًا.',
    reviewState: 'needs_review',
    active: true,
    workingInsight: marriageWorking,
    publishedInsight: null,
    insight: marriageWorking,
  },
  {
    id: 'worry-9-51',
    situationId: 'worriedOutcome',
    titleEn: 'When worry will not settle',
    titleAr: 'عندما لا يهدأ القلق',
    verseKey: '9:51',
    surahNameEn: 'At-Tawbah',
    surahNameAr: 'التوبة',
    ayahAr:
      'قُل لَّن يُصِيبَنَآ إِلَّا مَا كَتَبَ ٱللَّهُ لَنَا هُوَ مَوْلَىٰنَا ۚ وَعَلَى ٱللَّهِ فَلْيَتَوَكَّلِ ٱلْمُؤْمِنُونَ',
    meaningEn:
      'Say, “Never will we be struck except by what Allah has decreed for us; He is our protector.” And upon Allah let the believers rely.',
    orientationEn:
      'This reading steadies the heart without asking a person to ignore practical action, care, or support.',
    orientationAr:
      'يثبّت هذا الفهم القلب من غير أن يدعو الإنسان إلى ترك الأخذ بالأسباب أو الرعاية أو طلب المساندة.',
    reviewState: 'changed',
    active: true,
    workingInsight: worryWorking,
    publishedInsight: worryPublished,
    insight: worryWorking,
  },
  {
    id: 'bereavement-2-156',
    situationId: 'lostSomeone',
    titleEn: 'When you’ve lost someone you love',
    titleAr: 'عندما تفقد شخصًا تحبه',
    verseKey: '2:156',
    surahNameEn: 'Al-Baqarah',
    surahNameAr: 'البقرة',
    ayahAr:
      'ٱلَّذِينَ إِذَآ أَصَـٰبَتْهُم مُّصِيبَةٌ قَالُوٓا۟ إِنَّا لِلَّهِ وَإِنَّآ إِلَيْهِ رَٰجِعُونَ',
    meaningEn:
      'Who, when disaster strikes them, say, “Indeed we belong to Allah, and indeed to Him we will return.”',
    orientationEn:
      'This ayah gives words of belonging and return in bereavement; it does not ask someone to rush or suppress grief.',
    orientationAr:
      'تمنح هذه الآية المفجوع كلمات الانتماء إلى الله والرجوع إليه، ولا تطلب منه استعجال الحزن أو كتمانه.',
    reviewState: 'needs_review',
    active: true,
    workingInsight: bereavementWorking,
    publishedInsight: null,
    insight: bereavementWorking,
  },
  {
    id: 'giving-up-39-53',
    situationId: 'givingUp',
    titleEn: 'When you feel like giving up',
    titleAr: 'عندما تشعر أنك على وشك الاستسلام',
    verseKey: '39:53',
    surahNameEn: 'Az-Zumar',
    surahNameAr: 'الزمر',
    ayahAr:
      'قُلْ يَـٰعِبَادِىَ ٱلَّذِينَ أَسْرَفُوا۟ عَلَىٰٓ أَنفُسِهِمْ لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ ۚ إِنَّ ٱللَّهَ يَغْفِرُ ٱلذُّنُوبَ جَمِيعًا ۚ إِنَّهُۥ هُوَ ٱلْغَفُورُ ٱلرَّحِيمُ',
    meaningEn:
      'Do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful.',
    orientationEn:
      'The verse speaks directly against despair and toward sincere return, while the surrounding situation still deserves careful, human support.',
    orientationAr:
      'تنهى الآية عن اليأس وتفتح باب الرجوع الصادق، مع بقاء الحاجة إلى دعم إنساني متبصّر يراعي حال الشخص.',
    reviewState: 'needs_review',
    active: true,
    workingInsight: null,
    publishedInsight: givingUpPublished,
    insight: givingUpPublished,
  },
  {
    id: 'betrayed-8-58',
    situationId: 'betrayed',
    titleEn: 'When you’ve been deceived or betrayed',
    titleAr: 'عندما تتعرض للخداع أو الخيانة',
    verseKey: '8:58',
    surahNameEn: 'Al-Anfal',
    surahNameAr: 'الأنفال',
    ayahAr: '',
    meaningEn: '',
    orientationEn: 'Existing app orientation',
    orientationAr: 'وجه الاستدلال المعتمد حاليًا في التطبيق.',
    reviewState: 'changed',
    active: true,
    workingInsight: betrayedWorking,
    publishedInsight: null,
    insight: betrayedWorking,
  },
  {
    id: 'hardship-65-2',
    situationId: 'financialHardship',
    titleEn: 'When you’re facing financial hardship',
    titleAr: 'عندما تواجه ضائقة مالية',
    verseKey: '65:2-3',
    surahNameEn: 'At-Talaq',
    surahNameAr: 'الطلاق',
    ayahAr:
      'وَمَن يَتَّقِ ٱللَّهَ يَجْعَل لَّهُۥ مَخْرَجًا ۝ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
    meaningEn:
      'And whoever is mindful of Allah, He will make a way out for them and provide for them from sources they could never imagine.',
    orientationEn:
      'This passage places trust beside mindful action. It is not a promise of a particular amount or date.',
    orientationAr:
      'يجمع هذا المقطع بين التوكل والعمل الواعي، ولا يتضمن وعدًا بمبلغ محدد أو موعد بعينه.',
    reviewState: 'needs_review',
    active: true,
    workingInsight: hardshipWorking,
    publishedInsight: null,
    insight: hardshipWorking,
  },
  {
    id: 'mocked-49-11',
    situationId: 'mocked',
    titleEn: 'When people mock or belittle you',
    titleAr: 'عندما يسخر منك الناس أو ينتقصونك',
    verseKey: '49:11',
    surahNameEn: 'Al-Hujurat',
    surahNameAr: 'الحجرات',
    ayahAr: '',
    meaningEn: '',
    orientationEn: 'Existing app orientation',
    orientationAr: 'وجه الاستدلال المعتمد حاليًا في التطبيق.',
    reviewState: 'needs_review',
    active: true,
    workingInsight: mockedWorking,
    publishedInsight: null,
    insight: mockedWorking,
  },
]

export const demoProfile: ScholarProfile = {
  userId: 'demo-scholar',
  displayNameEn: 'Editorial contributor',
  displayNameAr: 'مساهم في المحتوى',
  titleEn: '',
  titleAr: '',
  bioEn: '',
  bioAr: '',
  avatarPath: '',
  facebookUrl: '',
  instagramUrl: '',
  youtubeUrl: '',
  tiktokUrl: '',
  websiteUrl: '',
  verified: false,
  isPublic: false,
}

export function freshDemoItems(role: AppRole = 'scholar'): GuidanceItem[] {
  const items = structuredClone(demoItems)
  if (role === 'scholar') return items
  return items.map((item) => {
    const workingInsight = item.workingInsight?.status === 'submitted' ? item.workingInsight : null
    const insight = workingInsight ?? item.publishedInsight ?? {
      ...blankInsight(`admin-empty-${item.id}`),
      id: null,
    }
    return { ...item, workingInsight, insight }
  })
}

export function freshDemoProfile(): ScholarProfile {
  return structuredClone(demoProfile)
}
