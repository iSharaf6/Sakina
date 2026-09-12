import Foundation

/// Compact interface themes for widget headlines. These never replace the
/// catalog's full situation titles, Qur'anic text, translations or citations.
enum WidgetSituationTitles {
    static let values: [String: (english: String, arabic: String)] = [
        // Before marriage
        "beforeMarriage": ("Before marriage", "قبل الزواج"),
        "lookingForSpouse": ("Seeking a good spouse", "البحث عن شريك صالح"),
        "choosingSpouse": ("Choosing a spouse", "اختيار شريك الحياة"),
        "waitingForTiming": ("Waiting for marriage", "انتظار الزواج"),
        "worriedNeverMarry": ("Fear of staying single", "الخوف من عدم الزواج"),
        "strugglingPatience": ("Finding patience", "التماس الصبر"),

        // Life together
        "peaceInMarriage": ("Peace in marriage", "السكينة في الزواج"),
        "treatSpouseKindly": ("Kindness to your spouse", "الإحسان إلى شريكك"),
        "becomeBetterSpouse": ("Being a better spouse", "أن تكون شريكًا أفضل"),
        "speakKindly": ("Speaking with kindness", "الكلام بلطف"),
        "decidingTogether": ("Deciding together", "اتخاذ القرار معًا"),
        "fairnessInMarriage": ("Fairness in marriage", "العدل في الزواج"),
        "rebuildingTrust": ("Rebuilding trust", "إعادة بناء الثقة"),
        "duaForFamily": ("Du’a for your family", "الدعاء للأسرة"),
        "feelingDistant": ("Distance in marriage", "التباعد بين الزوجين"),

        // Difficulties in marriage
        "marriageProblems": ("Marriage difficulties", "المشكلات الزوجية"),
        "constantlyArguing": ("Frequent arguments", "كثرة الخلافات"),
        "spouseWrongedYou": ("Hurt by your spouse", "الأذى من شريك الحياة"),
        "loweringAnger": ("Managing anger", "كظم الغيظ"),
        "forgivingSpouse": ("Forgiving your spouse", "مسامحة شريك الحياة"),
        "temptedToDivorce": ("Considering divorce", "التفكير في الطلاق"),
        "marriageTested": ("A marriage under strain", "ابتلاءات الزواج"),
        "afraidWontLast": ("Fear of separation", "الخوف من الفراق"),
        "questioningChoice": ("Doubting your choice", "مراجعة اختيارك"),
        "trustingPlan": ("Trusting Allah’s plan", "الثقة بتدبير الله"),
        "trustingTiming": ("Trusting Allah’s timing", "الصبر على أقدار الله"),
        "stayOrLeave": ("Staying or leaving", "البقاء أم الفراق"),

        // Family, separation and loss
        "raisingChildren": ("Raising children", "تربية الأبناء"),
        "prayingForChildren": ("Praying for children", "الدعاء بالذرية الصالحة"),
        "infertility": ("Waiting for a child", "تأخر الإنجاب"),
        "spouseAway": ("When your spouse is away", "غياب شريك الحياة"),
        "divorceUnavoidable": ("Facing divorce", "مواجهة الطلاق"),
        "afterDivorce": ("Life after divorce", "الحياة بعد الطلاق"),
        "grievingSpouse": ("Grieving your spouse", "الحزن على فقد الشريك"),

        // Faith and worship
        "needGuidance": ("Seeking guidance", "طلب الهداية"),
        "imanLow": ("When faith feels low", "ضعف الإيمان"),
        "salahConnection": ("Presence in prayer", "الخشوع في الصلاة"),
        "hardToPray": ("Struggling to pray", "صعوبة أداء الصلاة"),
        "losingFocus": ("Losing focus", "فقدان التركيز"),
        "forgettingBlessings": ("Remembering blessings", "تذكّر نعم الله"),
        "strugglingGrateful": ("Learning to be grateful", "تعلّم الشكر"),
        "fightingTemptation": ("Resisting temptation", "مقاومة المغريات"),
        "madeAMistake": ("After a mistake", "بعد الوقوع في خطأ"),
        "forgiveYourself": ("Despair after mistakes", "اليأس بعد الذنب"),
        "sameSin": ("Repeating a sin", "تكرار الذنب"),
        "selfControl": ("Self-control", "ضبط النفس"),

        // Worry and hardship
        "scaredOfFuture": ("Fear of the future", "الخوف من المستقبل"),
        "afraidOfFailure": ("Fear of failure", "الخوف من الفشل"),
        "worriedTomorrow": ("Worrying about tomorrow", "القلق بشأن الغد"),
        "feelAlone": ("Feeling alone", "الشعور بالوحدة"),
        "tooManyBurdens": ("Too much to carry", "ثقل الأعباء"),
        "disappointed": ("Disappointment", "خيبة الأمل"),
        "movingOn": ("Trying to move on", "محاولة تجاوز الماضي"),
        "everyoneAhead": ("Comparing your progress", "مقارنة تقدمك بالآخرين"),
        "someoneHurtsYou": ("When someone hurts you", "حين يؤذيك أحد"),
        "needToForgive": ("Forgiving others", "العفو عن الآخرين"),
        "afraidPeopleThink": ("Fear of others’ opinions", "الخوف من آراء الناس"),
        "feelingInsecure": ("Feeling insecure", "الشعور بعدم الأمان"),
        "facingRejection": ("Facing rejection", "مواجهة الرفض"),

        // Work and provision
        "worriedAboutRizq": ("Worry about provision", "القلق على الرزق"),
        "strugglingFinancially": ("Financial hardship", "الضائقة المالية"),
        "hesitantCharity": ("Hesitating to give", "التردد في الصدقة"),
        "comparingFinances": ("Comparing finances", "مقارنة الأوضاع المالية"),
        "financialBurdens": ("Financial burdens", "الأعباء المالية"),
        "moneyStress": ("Money worries", "الهموم المالية"),
        "afraidToSpend": ("Giving for Allah", "الإنفاق في سبيل الله"),
        "tomorrowRizq": ("Tomorrow’s provision", "رزق الغد"),
        "workNoResults": ("Effort without results", "جهد بلا نتائج"),
        "heartAttachedMoney": ("Attachment to money", "التعلق بالمال"),
        "barakahInWealth": ("Barakah in your wealth", "البركة في المال"),
        "provisionDelayed": ("When provision feels late", "الشعور بتأخر الرزق"),
        "salaryNotEnough": ("When pay isn’t enough", "حين لا يكفي الراتب"),
        "scaredStartBusiness": ("Starting a business", "بدء مشروع جديد"),
        "stuckFinancially": ("Feeling stuck financially", "تعثر الوضع المالي"),
        "jealousOfSuccess": ("Envy of others’ success", "الغيرة من نجاح الآخرين"),
        "providingForFamily": ("Providing for family", "الإنفاق على الأسرة"),
        "afraidToRisk": ("Fear of taking risks", "الخوف من المخاطرة"),
        "majorFinancialDecision": ("Big financial decisions", "قرارات مالية مهمة"),
        "impatientForResults": ("Waiting for results", "انتظار النتائج"),
        "everyoneAheadDuha": ("Feeling left behind", "الشعور بالتأخر"),
        "payingBills": ("Paying the bills", "سداد الفواتير"),
        "stressedAboutDebt": ("The weight of debt", "ثقل الدَّين"),
        "losingJob": ("Fear of losing your job", "الخوف من فقدان العمل"),
        "savingsLow": ("Savings running low", "تناقص المدخرات"),
    ]

    static var missingSituationIDs: [String] {
        Set(SituationCatalog.all.map(\.id)).subtracting(values.keys).sorted()
    }
}

extension Situation {
    func widgetTitle(_ language: AppLanguage) -> String {
        guard let title = WidgetSituationTitles.values[id] else { return localizedTitle(language) }
        return language.pick(title.english, title.arabic)
    }
}
