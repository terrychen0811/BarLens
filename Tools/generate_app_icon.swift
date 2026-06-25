import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent(".build/AppIcon.iconset", isDirectory: true)
let output = root.appendingPathComponent("Resources/AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(size: Int) throws -> URL {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.09, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22).fill()

    let bandHeight = CGFloat(size) * 0.16
    let bandRect = NSRect(x: CGFloat(size) * 0.13, y: CGFloat(size) * 0.67, width: CGFloat(size) * 0.74, height: bandHeight)
    NSColor(calibratedRed: 0.86, green: 0.92, blue: 0.96, alpha: 1).setFill()
    NSBezierPath(roundedRect: bandRect, xRadius: bandHeight / 2, yRadius: bandHeight / 2).fill()

    let colors: [NSColor] = [
        NSColor(calibratedRed: 0.32, green: 0.79, blue: 0.62, alpha: 1),
        NSColor(calibratedRed: 0.98, green: 0.76, blue: 0.28, alpha: 1),
        NSColor(calibratedRed: 0.39, green: 0.65, blue: 0.96, alpha: 1)
    ]
    for index in 0..<3 {
        let diameter = CGFloat(size) * 0.08
        let x = CGFloat(size) * (0.2 + CGFloat(index) * 0.14)
        let y = CGFloat(size) * 0.71
        colors[index].setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: diameter, height: diameter)).fill()
    }

    let lens = NSRect(x: CGFloat(size) * 0.26, y: CGFloat(size) * 0.21, width: CGFloat(size) * 0.40, height: CGFloat(size) * 0.40)
    NSColor(calibratedRed: 0.91, green: 0.96, blue: 0.98, alpha: 1).setStroke()
    let lensPath = NSBezierPath(ovalIn: lens)
    lensPath.lineWidth = CGFloat(size) * 0.055
    lensPath.stroke()

    let handle = NSBezierPath()
    handle.move(to: NSPoint(x: CGFloat(size) * 0.59, y: CGFloat(size) * 0.27))
    handle.line(to: NSPoint(x: CGFloat(size) * 0.76, y: CGFloat(size) * 0.11))
    handle.lineCapStyle = .round
    handle.lineWidth = CGFloat(size) * 0.07
    handle.stroke()

    NSColor(calibratedRed: 0.39, green: 0.65, blue: 0.96, alpha: 0.55).setFill()
    NSBezierPath(ovalIn: NSRect(x: CGFloat(size) * 0.36, y: CGFloat(size) * 0.35, width: CGFloat(size) * 0.12, height: CGFloat(size) * 0.12)).fill()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let url = iconset.appendingPathComponent("icon_\(size)x\(size).png")
    try png.write(to: url)
    return url
}

let baseSizes = [16, 32, 128, 256, 512]
for size in baseSizes {
    let normal = try drawIcon(size: size)
    let retina = try drawIcon(size: size * 2)
    let normalName = "icon_\(size)x\(size).png"
    let retinaName = "icon_\(size)x\(size)@2x.png"
    try FileManager.default.moveItem(at: normal, to: iconset.appendingPathComponent(normalName))
    try FileManager.default.moveItem(at: retina, to: iconset.appendingPathComponent(retinaName))
}

try? FileManager.default.removeItem(at: output)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw CocoaError(.fileWriteUnknown)
}
