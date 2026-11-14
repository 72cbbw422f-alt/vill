import AppKit
import Foundation

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets.xcassets/AppIcon.appiconset"
let directory = URL(fileURLWithPath: output, isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("No drawing context") }
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let bounds = CGRect(origin: .zero, size: canvas)
let background = NSColor(calibratedRed: 0.055, green: 0.145, blue: 0.105, alpha: 1)
let brass = NSColor(calibratedRed: 0.76, green: 0.59, blue: 0.30, alpha: 1)
let pale = NSColor(calibratedRed: 0.91, green: 0.86, blue: 0.72, alpha: 1)
let blue = NSColor(calibratedRed: 0.12, green: 0.27, blue: 0.43, alpha: 1)

background.setFill()
NSBezierPath(roundedRect: bounds, xRadius: 190, yRadius: 190).fill()

let inset = CGRect(x: 42, y: 42, width: 940, height: 940)
brass.withAlphaComponent(0.8).setStroke()
let frame = NSBezierPath(roundedRect: inset, xRadius: 160, yRadius: 160)
frame.lineWidth = 10
frame.stroke()

// Magnifying glass handle
let handle = NSBezierPath()
handle.move(to: NSPoint(x: 650, y: 365))
handle.curve(to: NSPoint(x: 890, y: 125), controlPoint1: NSPoint(x: 735, y: 280), controlPoint2: NSPoint(x: 810, y: 205))
brass.setStroke()
handle.lineWidth = 82
handle.lineCapStyle = .round
handle.stroke()

let handleHighlight = NSBezierPath()
handleHighlight.move(to: NSPoint(x: 650, y: 365))
handle.curve(to: NSPoint(x: 890, y: 125), controlPoint1: NSPoint(x: 735, y: 280), controlPoint2: NSPoint(x: 810, y: 205))
pale.withAlphaComponent(0.55).setStroke()
handleHighlight.lineWidth = 12
handleHighlight.lineCapStyle = .round
handleHighlight.stroke()

// Lens and rim
let lensRect = CGRect(x: 130, y: 300, width: 590, height: 590)
let lens = NSBezierPath(ovalIn: lensRect)
brass.setStroke()
lens.lineWidth = 34
lens.stroke()
NSColor(calibratedRed: 0.075, green: 0.19, blue: 0.14, alpha: 1).setFill()
NSBezierPath(ovalIn: lensRect.insetBy(dx: 20, dy: 20)).fill()

// Porcelain vase silhouette
let vase = NSBezierPath()
vase.move(to: NSPoint(x: 360, y: 395))
vase.curve(to: NSPoint(x: 430, y: 515), controlPoint1: NSPoint(x: 370, y: 435), controlPoint2: NSPoint(x: 415, y: 475))
vase.curve(to: NSPoint(x: 420, y: 680), controlPoint1: NSPoint(x: 445, y: 570), controlPoint2: NSPoint(x: 445, y: 625))
vase.curve(to: NSPoint(x: 365, y: 755), controlPoint1: NSPoint(x: 415, y: 715), controlPoint2: NSPoint(x: 390, y: 745))
vase.line(to: NSPoint(x: 510, y: 755))
vase.curve(to: NSPoint(x: 455, y: 680), controlPoint1: NSPoint(x: 485, y: 745), controlPoint2: NSPoint(x: 460, y: 715))
vase.curve(to: NSPoint(x: 445, y: 515), controlPoint1: NSPoint(x: 430, y: 625), controlPoint2: NSPoint(x: 430, y: 570))
vase.curve(to: NSPoint(x: 515, y: 395), controlPoint1: NSPoint(x: 460, y: 475), controlPoint2: NSPoint(x: 505, y: 435))
vase.close()
pale.setFill()
vase.fill()
brass.setStroke()
vase.lineWidth = 8
vase.stroke()

// Vase neck and foot
let neck = NSBezierPath(roundedRect: CGRect(x: 355, y: 745, width: 165, height: 48), xRadius: 12, yRadius: 12)
pale.setFill()
neck.fill()
brass.setStroke()
neck.lineWidth = 7
neck.stroke()
let foot = NSBezierPath(roundedRect: CGRect(x: 345, y: 375, width: 185, height: 35), xRadius: 10, yRadius: 10)
pale.setFill()
foot.fill()
brass.setStroke()
foot.lineWidth = 7
foot.stroke()

// Blue decorative bands and a simple floral motif
blue.setStroke()
let band1 = NSBezierPath()
band1.move(to: NSPoint(x: 375, y: 465)); band1.line(to: NSPoint(x: 500, y: 465))
band1.move(to: NSPoint(x: 375, y: 700)); band1.line(to: NSPoint(x: 500, y: 700))
band1.lineWidth = 12
band1.stroke()
let stem = NSBezierPath()
stem.move(to: NSPoint(x: 438, y: 520))
stem.curve(to: NSPoint(x: 438, y: 665), controlPoint1: NSPoint(x: 390, y: 560), controlPoint2: NSPoint(x: 490, y: 620))
stem.lineWidth = 9
stem.stroke()
for (x, y, angle) in [(405.0, 575.0, -25.0), (475.0, 610.0, 25.0), (410.0, 640.0, -15.0)] {
    let leaf = NSBezierPath(ovalIn: CGRect(x: x, y: y, width: 42, height: 20))
    leaf.transform(using: AffineTransform(rotationByDegrees: angle))
    leaf.lineWidth = 7
    leaf.stroke()
}
let flower = NSBezierPath(ovalIn: CGRect(x: 418, y: 575, width: 42, height: 42))
flower.lineWidth = 8
flower.stroke()

// Small decorative glint
let glint = NSBezierPath()
glint.move(to: NSPoint(x: 240, y: 820)); glint.line(to: NSPoint(x: 240, y: 860))
glint.move(to: NSPoint(x: 220, y: 840)); glint.line(to: NSPoint(x: 260, y: 840))
glint.lineWidth = 7
pale.withAlphaComponent(0.8).setStroke()
glint.stroke()

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
try png.write(to: directory.appendingPathComponent("AppIcon.png"))
let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try contents.write(to: directory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Generated Antikspanaren AppIcon at \(directory.path)")
