// Vẽ icon app 1024×1024: nền bo góc gradient xanh, tấm clipboard trắng, số "9".
// Dùng: swift scripts/make-icon.swift <out.png>   (scripts/make-icon.sh gọi và đóng gói .icns)
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.dropFirst().first ?? "icon.png"

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Khung icon chuẩn macOS: 824px trong canvas 1024, bo góc ~185px.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor.black.setFill()
tilePath.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(
    starting: NSColor(red: 0.36, green: 0.62, blue: 1.00, alpha: 1),
    ending: NSColor(red: 0.20, green: 0.33, blue: 0.86, alpha: 1))!
    .draw(in: tilePath, angle: -90)

// Tấm giấy clipboard.
let board = NSRect(x: 292, y: 210, width: 440, height: 560)
NSColor.white.withAlphaComponent(0.96).setFill()
NSBezierPath(roundedRect: board, xRadius: 56, yRadius: 56).fill()

// Kẹp ở trên.
let clip = NSRect(x: 412, y: 722, width: 200, height: 96)
NSColor(red: 0.13, green: 0.20, blue: 0.45, alpha: 1).setFill()
NSBezierPath(roundedRect: clip, xRadius: 30, yRadius: 30).fill()

// Số 9.
let font = NSFont.systemFont(ofSize: 400, weight: .heavy)
let nine = NSAttributedString(string: "9", attributes: [
    .font: font,
    .foregroundColor: NSColor(red: 0.20, green: 0.38, blue: 0.92, alpha: 1),
])
let textSize = nine.size()
nine.draw(at: NSPoint(x: board.midX - textSize.width / 2, y: board.midY - textSize.height / 2 - 30))

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
