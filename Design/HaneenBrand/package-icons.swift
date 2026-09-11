import AppKit
import ImageIO
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
// Run from the repository root after the approved transparent master is installed.
let src = CGImageSourceCreateWithURL(root.appendingPathComponent("Shared/CompanionAssets.xcassets/YaqeenBrand.imageset/logo.png") as CFURL, nil)!
let img=CGImageSourceCreateImageAtIndex(src,0,nil)!
print("Brand alpha:", img.alphaInfo.rawValue)
func icon(_ size:Int,_ path:String) throws {
 let ctx=CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:size*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
 ctx.setFillColor(CGColor(red:0.99,green:0.98,blue:0.95,alpha:1));ctx.fill(CGRect(x:0,y:0,width:size,height:size))
 ctx.interpolationQuality = .high
 ctx.draw(img,in:CGRect(x:0,y:0,width:size,height:size))
 let out=CGImageDestinationCreateWithURL(root.appendingPathComponent(path) as CFURL,"public.png" as CFString,1,nil)!
 CGImageDestinationAddImage(out,ctx.makeImage()!,nil);CGImageDestinationFinalize(out)
}
let dir="Sakina/Assets.xcassets/AppIcon.appiconset/"
let json=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent(dir+"Contents.json"))) as! [String:Any]
for item in json["images"] as! [[String:String]] { let size=Double(item["size"]!.components(separatedBy:"x")[0])! * Double(item["scale"]!.dropLast())!;try icon(Int(size),dir+item["filename"]!) }
try icon(120,"Sakina/Resources/AppIcon60x60@2x.png")
try icon(180,"Sakina/Resources/AppIcon60x60@3x.png")
try icon(152,"Sakina/Resources/AppIcon76x76@2x.png")
