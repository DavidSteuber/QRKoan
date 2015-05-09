//
//  main.swift
//  QRKoan
//
//  Created by David Steuber on 4/28/15.
//  Copyright (c) 2015 David Steuber.
//
//  Create a Quick Response code that contains a representation of itself
//  by looking for a "zero point". What would be really cool is to create
//  a QR code that represents a PNG file representing that QR code.

import Foundation
import QuartzCore

let fileName = "/Users/david/Desktop/test.png"
let maxCapacity = 2953

// Quick Response code generator
func qrCodeWithMessage(data: NSData) -> CIImage? {
    if data.length > maxCapacity {
        println("Data length \(data.length) exceeds maxCapacity of \(maxCapacity)")
        return nil
    }

    let qrEncoder = CIFilter(name: "CIQRCodeGenerator", withInputParameters: ["inputMessage":data, "inputCorrectionLevel":"L"])
    let ciImage = qrEncoder.outputImage

    return ciImage
}

func colorSpaceIndexed() -> CGColorSpace! {
    let colorTable = [0, 255]
    let graySpace = CGColorSpaceCreateDeviceGray()

    return CGColorSpaceCreateIndexed(graySpace!, 1, UnsafePointer<UInt8>(colorTable))
}

func createBitmapContext (size: CGRect) -> CGContext! {
    let context = CGBitmapContextCreate(nil,
        Int(size.width),
        Int(size.height),
        8,
        0,
        CGColorSpaceCreateDeviceGray(),
        CGBitmapInfo(CGImageAlphaInfo.None.rawValue))
    CGContextSetInterpolationQuality(context, kCGInterpolationNone)
    CGContextSetShouldAntialias(context, false)

    return context
}

func createCGImage(ci: CIImage) -> CGImage? {
    let contextOptions = [kCIContextOutputColorSpace: colorSpaceIndexed(),
        kCIContextWorkingColorSpace: NSNull(),
        kCIContextUseSoftwareRenderer: true]
    let cgContext = createBitmapContext(ci.extent())
    let context = CIContext(CGContext: cgContext, options: contextOptions as [NSObject : AnyObject])

    CGContextDrawImage(cgContext, ci.extent(), context.createCGImage(ci, fromRect: ci.extent()))

    return CGBitmapContextCreateImage(cgContext)
}

func saveImage(path: String, image: NSData) {
    image.writeToFile(path, atomically: true)
}

func getImageFileData(image: CGImage) -> NSData? {
    var pngDataRef = CFDataCreateMutable(nil, 0)
    let pngDest = CGImageDestinationCreateWithData(pngDataRef, kUTTypePNG, 1, nil)
    CGImageDestinationAddImage(pngDest, image, nil)
    CGImageDestinationFinalize(pngDest)

    return pngDataRef
}

func compare(d1: NSData, d2: NSData) -> Bool {
    if d1.length == d2.length {
        let m = d1.bytes
        let n = d2.bytes
        for i in 0 ..< d1.length {
            if m != n {
                println("different byte at index \(i) of \(d1.length)")
                return false
            }
        }
    } else {
        println("different lengths: \(d1.length), \(d2.length)")
        return false
    }

    return true
}

func main() {
    var qrcode = qrCodeWithMessage(NSData()) // initial image with null data
    var image = createCGImage(qrcode!)
    var data = getImageFileData(image!)
    var round = 1

    do {
        print("Round \(round): ")
        if let qrcode2 = qrCodeWithMessage(data!),
            let image2 = createCGImage(qrcode2),
            let data2 = getImageFileData(image2) {
                if compare(data!, data2) {
                    break
                } else {
                    qrcode = qrcode2
                    image = image2
                    data = data2
                    round++
                }
        } else {
            break
        }
        if data!.length > maxCapacity {
            println("Non convergence!")
            break
        }
    } while true

    saveImage(fileName, data!)
}

main()