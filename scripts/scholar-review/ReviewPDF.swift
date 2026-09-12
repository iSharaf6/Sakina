import AppKit
import CoreText
import PDFKit

// CoreText performs Arabic shaping and bidirectional layout directly in the PDF.
// Text is copied from the exported catalog; the review areas contain no attributed insights.
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
func read(_ name: String) throws -> Any { try JSONSerialization.jsonObject(with: Data(contentsOf: input.appendingPathComponent(name))) }
let situations = try read("haneen-situations.json") as! [[String:Any]]
let groups = try read("haneen-groups.json") as! [[String:Any]]
let moods = try read("haneen-moods.json") as! [[String:Any]]
let duas = try read("haneen-duas.json") as! [[String:Any]]
let verseFile = try read("verses.json") as! [String:Any]
let verses = Dictionary(uniqueKeysWithValues: (verseFile["verses"] as! [[String:Any]]).map { ($0["key"] as! String,$0) })
let bySituation = Dictionary(uniqueKeysWithValues:situations.map { ($0["id"] as! String,$0) })
let byDua = Dictionary(uniqueKeysWithValues:duas.map { ($0["id"] as! String,$0) })
let quranFile = try read("quran.json") as! [String:Any]
let surahNames = Dictionary(uniqueKeysWithValues:(quranFile["surahs"] as! [[String:Any]]).map { ($0["n"] as! Int,$0["ar"] as! String) })
let dark = NSColor(calibratedRed:0.10,green:0.16,blue:0.13,alpha:1)
let green = NSColor(calibratedRed:0.21,green:0.37,blue:0.28,alpha:1)
let muted = NSColor(calibratedWhite:0.38,alpha:1)
let pageW:CGFloat = 595.28, pageH:CGFloat = 841.89, margin:CGFloat = 48
let textW = pageW - 2*margin

final class ReviewPDF {
    let ctx: CGContext
    let url: URL
    var y:CGFloat = 0
    var page = 0
    var title: String
    var entryTitle = ""
    var entryID = ""
    var bookmarks:[(String,Int)] = []
    var entryPages:[String:Int] = [:]
    init(_ filename:String,_ title:String) {
        self.title=title;url=output.appendingPathComponent(filename)
        var box=CGRect(x:0,y:0,width:pageW,height:pageH)
        let metadata=[kCGPDFContextTitle as String:title,kCGPDFContextAuthor as String:"حنين",kCGPDFContextSubject as String:"نسخة للمراجعة وإضافة التعليقات وليست اعتمادًا علميًا"]
        ctx=CGContext(url as CFURL,mediaBox:&box,metadata as CFDictionary)!
    }
    func attributed(_ text:String,_ size:CGFloat,_ color:NSColor = dark,_ rtl:Bool = true) -> NSAttributedString {
        let style=NSMutableParagraphStyle()
        style.baseWritingDirection=rtl ? .rightToLeft : .leftToRight
        style.alignment=rtl ? .right : .left
        style.lineSpacing=5
        let font=NSFont(name:"GeezaPro",size:size) ?? NSFont.systemFont(ofSize:size)
        return NSAttributedString(string:text,attributes:[.font:font,.foregroundColor:color,.paragraphStyle:style])
    }
    func draw(_ text:String,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,size:CGFloat,color:NSColor = dark,rtl:Bool=true) {
        let a=attributed(text,size,color,rtl)
        let frame=CTFramesetterCreateFrame(CTFramesetterCreateWithAttributedString(a),CFRange(location:0,length:0),CGPath(rect:CGRect(x:x,y:y,width:w,height:h),transform:nil),nil)
        precondition(CTFrameGetVisibleStringRange(frame).length == a.length, "Clipped text on page \(page): \(text.prefix(50))")
        CTFrameDraw(frame,ctx)
    }
    func newPage() {
        if page>0 { footer();ctx.endPDFPage() }
        ctx.beginPDFPage(nil);page+=1;y=pageH-85
        ctx.setFillColor(NSColor.white.cgColor);ctx.fill(CGRect(x:0,y:0,width:pageW,height:pageH))
        draw("حنين  |  \(title)",x:margin,y:pageH-51,w:textW,h:25,size:10,color:green)
        if !entryID.isEmpty { draw(entryID,x:margin,y:pageH-68,w:textW,h:17,size:8,color:muted,rtl:false) }
    }
    func footer() {
        draw("نسخة للمراجعة  |  ١٢ سبتمبر ٢٠٢٦",x:margin,y:22,w:textW,h:20,size:9,color:muted)
        draw(String(page),x:margin,y:22,w:40,h:20,size:9,color:muted,rtl:false)
    }
    func block(_ text:String,size:CGFloat=14,color:NSColor=dark,gap:CGFloat=12,rtl:Bool=true) {
        guard !text.isEmpty else{return}
        let a=attributed(text,size,color,rtl)
        let fs=CTFramesetterCreateWithAttributedString(a)
        var range=CFRange(location:0,length:0)
        let height=ceil(CTFramesetterSuggestFrameSizeWithConstraints(fs,range,nil,CGSize(width:textW,height:100000),nil).height)+9
        if y-height < 50 && height < pageH-145 {newPage()}
        if height < pageH-145 {
            draw(text,x:margin,y:y-height,w:textW,h:height,size:size,color:color,rtl:rtl);y-=height+gap
        } else {
            while range.location<a.length {
                if y<130 {newPage()}
                let h=y-52
                let frame=CTFramesetterCreateFrame(fs,CFRange(location:range.location,length:0),CGPath(rect:CGRect(x:margin,y:52,width:textW,height:h),transform:nil),nil)
                let visible=CTFrameGetVisibleStringRange(frame)
                precondition(visible.length>0,"Text failed to paginate")
                CTFrameDraw(frame,ctx);range.location+=visible.length;y=52
                if range.location<a.length {newPage()}
            }
            y-=gap
        }
    }
    func heading(_ text:String) { if y<150 {newPage()};block(text,size:17,color:green,gap:6) }
    func source(_ source:[String:Any]) {
        let label="\(source["collectionArabic"] as? String ?? "")  \(source["number"] as? String ?? "")  |  \(source["gradeArabic"] as? String ?? "")"
        block(label,size:10,color:muted,gap:3)
        if let url=source["canonicalURL"] as? String {
            let h:CGFloat=22;if y-h<50 {newPage()}
            draw(url,x:margin,y:y-h,w:textW,h:h,size:8,color:green,rtl:false)
            if let u=URL(string:url){ctx.setURL(u as CFURL,for:CGRect(x:margin,y:y-h,width:textW,height:h))}
            y-=h+8
        }
    }
    func cover(_ intro:String) {
        newPage();y-=35
        block(title,size:28,gap:24)
        block("ملف مراجعة وإضافة إضاءات عربية",size:20,color:green,gap:28)
        block("مقدّم إلى المراجع",size:18,gap:24)
        block(intro,size:15,gap:20)
        block("نرجو إضافة إضاءة موجزة بأسلوبكم تصل النصوص بحال القارئ، مع تنبيه على ما يحتاج تصحيحًا أو تقييدًا. يمكن الكتابة على الصفحات بالقلم أو إضافة تعليقات PDF. يبقى معرّف كل مدخل ثابتًا لربط ملاحظاتكم بمكانها في التطبيق.",size:14,gap:18)
        block("النصوص والسياق من نسخة التطبيق الحالية. عرضها هنا لا يعني اعتمادكم لها، ولن تُنسب إليكم أي إضاءة قبل أن تكتبوها وتوافقوا على نشرها.",size:14,gap:18)
        block("في بداية كل مدخل الآيات بأسماء السور وأرقامها، ثم الأحاديث والأدعية مع مصادرها. المقاطع الموسومة بمقتطف تُراجع في مصدرها الكامل.",size:14)
        newPage()
        block("بيانات الشيخ وطريقة إعادة الملف",size:25,gap:22)
        block("يمكنكم إنجاز المداخل على دفعات، وإعادة الملف كاملًا أو الصفحات المكتملة فقط. عند كتابة تعليق في ملف آخر، نرجو وضع معرّف المدخل الظاهر أعلى الصفحة مع كل تعليق.",size:14,gap:24)
        heading("بيانات الظهور في التطبيق")
        block("الاسم والصفة اللذان تفضلونهما للنشر",size:12,gap:0);lines(2)
        block("نبذة قصيرة وروابطكم العامة التي ترغبون في إضافتها",size:12,gap:0);lines(6)
        heading("الموافقة على نسبة الإضاءات")
        block("بعد اكتمال المراجعة، نرجو تحديد الاسم والصفة المرغوبين للنشر، والمداخل التي توافقون على نسبتها إليكم. تبقى الإضاءات غير المنشورة مسودات مراجعة حتى اعتمادكم.",size:14)
        lines(3)
    }
    func beginEntry(_ id:String,_ name:String,_ group:String) {
        entryID=id;entryTitle=name;newPage();entryPages[id]=page;bookmarks.append((name,page-1))
        block(group,size:11,color:muted,gap:4);block(name,size:23,gap:14)
    }
    func lines(_ count:Int) {
        ctx.setStrokeColor(NSColor(calibratedWhite:0.80,alpha:1).cgColor);ctx.setLineWidth(0.4)
        for _ in 0..<count { if y<82 {newPage()};y-=25;ctx.move(to:CGPoint(x:margin,y:y));ctx.addLine(to:CGPoint(x:pageW-margin,y:y));ctx.strokePath() }
        y-=12
    }
    func response() {
        // Give each entry a clearly labelled full response page, never a sliver at the bottom.
        newPage();block(entryTitle,size:21,gap:12)
        heading("إضاءة المراجع")
        block("ما المعنى الأهم الذي تحبون إيصاله للقارئ في هذا الحال؟ يمكن إضافة توجيه عملي أو تعليق يوضح صلة النصوص بالموضوع.",size:12,gap:2);lines(10)
        heading("ملاحظات على النصوص والمصادر")
        block("أي تصحيح أو تقييد أو مصدر إضافي تقترحونه",size:12,gap:2);lines(4)
        heading("قرار المراجعة")
        block("مناسب للنشر    /    يحتاج تعديلًا    /    لا يُنشر حاليًا",size:12)
        block("التاريخ والتوقيع",size:11,gap:0);lines(1)
    }
    func entryText(_ e:[String:Any],_ kind:String) {
        typealias Piece=(String,CGFloat,NSColor,CGFloat,Bool)
        var parts:[Piece]=[("\(kind)  |  \(e["titleArabic"] as? String ?? "")",16,green,5,true)]
        let src=e["source"] as! [String:Any]
        if src["kind"] as? String == "quran" {
            // Some Qur’anic entries cite the hadith prescribing their recitation.
            // Its hadith number must never be interpreted as a surah number.
            let id=e["id"] as? String ?? ""
            let number=src["number"] as? String ?? ""
            let labels=["afterSalah-ayat-al-kursi":"سورة البقرة، الآية ٢٥٥",
                        "healing-ayat-al-kursi":"سورة البقرة، الآية ٢٥٥",
                        "healing-fatihah-as-ruqyah":"سورة الفاتحة كاملة",
                        "afterSalah-three-quls":"سور الإخلاص والفلق والناس كاملة",
                        "healing-three-quls":"سور الإخلاص والفلق والناس كاملة",
                        "sleep-three-quls":"سور الإخلاص والفلق والناس كاملة"]
            if let label=labels[id] {parts.append((label,11,green,2,true))}
            else if number.contains(":"),let n=Int(number.split(separator:":").first ?? ""),let name=surahNames[n] {
                parts.append(("سورة \(name)",11,green,2,true))
            }
        }
        if src["textForm"] as? String == "excerpt" {parts.append(("مقتطف من النص",10,muted,2,true))}
        parts.append((e["arabic"] as? String ?? "",16,dark,6,true))
        parts.append(("\(src["collectionArabic"] as? String ?? "")  \(src["number"] as? String ?? "")  |  \(src["gradeArabic"] as? String ?? "")",10,muted,2,true))
        parts.append((src["canonicalURL"] as? String ?? "",8,green,6,false))
        if let caution=e["cautionArabic"] as? String,!caution.isEmpty {parts.append((caution,11,muted,8,true))}
        let required=parts.reduce(CGFloat(0)) { total,piece in
            let fs=CTFramesetterCreateWithAttributedString(attributed(piece.0,piece.1,piece.2,piece.4))
            return total+ceil(CTFramesetterSuggestFrameSizeWithConstraints(fs,CFRange(location:0,length:0),nil,CGSize(width:textW,height:100000),nil).height)+9+piece.3
        }
        if required<pageH-145 && y-required<52 {newPage()}
        for piece in parts {
            let before=y
            block(piece.0,size:piece.1,color:piece.2,gap:piece.3,rtl:piece.4)
            if !piece.4,let u=URL(string:piece.0),u.scheme=="https" {ctx.setURL(u as CFURL,for:CGRect(x:margin,y:y,width:textW,height:max(16,before-y)))}
        }
        y-=6
    }
    func finish() {
        footer();ctx.endPDFPage();ctx.closePDF()
        let doc=PDFDocument(url:url)!
        let outline=PDFOutline();outline.label=title
        for (name,index) in bookmarks {
            let node=PDFOutline();node.label=name;node.destination=PDFDestination(page:doc.page(at:index)!,at:CGPoint(x:0,y:pageH));outline.insertChild(node,at:outline.numberOfChildren)
        }
        doc.outlineRoot=outline;doc.write(to:url)
        let map=try! JSONSerialization.data(withJSONObject:entryPages,options:[.prettyPrinted,.sortedKeys])
        try! map.write(to:input.appendingPathComponent(url.deletingPathExtension().lastPathComponent+"-pages.json"))
        print("\(url.lastPathComponent): \(page) pages, \(entryPages.count) entries")
    }
}

let life=ReviewPDF("Haneen-Life-Situations-Arabic-Review.pdf","أين أنت في الحياة")
life.cover("يجمع هذا الملف المواقف الحياتية الأربعة والثمانين في تطبيق حنين، مرتبة بحسب أبواب الزواج والأسرة والإيمان والعافية والرزق. المطلوب مراجعة المادة وكتابة إضاءة عربية خاصة بكل موقف.")
var seen=Set<String>()
for group in groups {
 for stage in group["stages"] as! [[String:Any]] {
  for id in stage["ids"] as! [String] {
   guard seen.insert(id).inserted, let entry=bySituation[id] else {continue}
   life.beginEntry(id,entry["title"] as! String,"\(group["title"] as! String)  /  \(stage["title"] as! String)")
   life.heading("السياق الحالي في التطبيق")
   life.block(entry["context"] as! String,size:12,color:muted)
   for key in entry["verses"] as! [String] {
     guard let verse=verses[key] else {fatalError("Missing verse \(key)")}
     life.heading("سورة \(verse["surahNameArabic"] as! String)  |  \(key)")
     life.block(verse["arabic"] as! String,size:18)
     life.block("https://quran.com/\(key.replacingOccurrences(of:":",with:"/"))",size:8,color:green,rtl:false)
   }
   for h in entry["hadiths"] as! [[String:Any]] {life.entryText(h,"حديث")}
   for d in entry["duas"] as! [[String:Any]] {life.entryText(d,"دعاء")}
   life.response()
  }
 }
}
precondition(seen.count==situations.count,"Every situation must appear")
life.finish()
let feelings=ReviewPDF("Haneen-Feelings-Arabic-Review.pdf","المشاعر وما يواسي القلب")
feelings.cover("يجمع هذا الملف المشاعر الثلاثة والثلاثين المعروضة في التطبيق، ومع كل شعور جميع القراءات المرتبطة به حاليًا. تضم القراءات آيات وأدعية قرآنية وأدعية نبوية مسندة إلى أحاديثها. ليس لكل شعور حديث مستقل إضافي في التطبيق؛ لذلك لم نضف نصوصًا من عندنا. اختيار النص تحت شعور هو تنظيم للتأمل وليس تخصيصًا شرعيًا لوعد أو عدد.")
for mood in moods {
 let id=mood["id"] as! String
 feelings.beginEntry("feeling-"+id,mood["title"] as! String,"المشاعر")
 for duaID in mood["ids"] as! [String] {
  guard let dua=byDua[duaID] else {fatalError("Missing \(duaID)")}
  feelings.entryText(dua,dua["kind"] as? String == "quranic" ? "قراءة قرآنية" : "دعاء نبوي أو حديث")
 }
 feelings.response()
}
feelings.finish()
