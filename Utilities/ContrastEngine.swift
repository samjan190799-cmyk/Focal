//
// ContrastEngine.swift
// FocalApp
//
// Адаптивный движок контрастности текста поверх фоновых изображений (CoreImage)
//

import SwiftUI
import CoreImage

@MainActor
public final class ContrastEngine {
    public static let shared = ContrastEngine()
    
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    private init() {}
    
    /// Анализирует Data изображения и вычисляет относительную яркость (Luminance)
    /// Возвращает recommendedForegroundColor: Color (.white или .black/.primary)
    public func analyzeLuminance(imageData: Data?, defaultColor: Color = .primary) -> (isDarkBackground: Bool, recommendedColor: Color, shadowOpacity: Double) {
        guard let imageData,
              let ciImage = CIImage(data: imageData) else {
            return (false, defaultColor, 0.0)
        }
        
        // Масштабируем изображение до 1x1 пикселя через CIAreaAverage
        let extentVector = CIVector(x: ciImage.extent.origin.x,
                                   y: ciImage.extent.origin.y,
                                   z: ciImage.extent.size.width,
                                   w: ciImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return (false, defaultColor, 0.0)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let red = Double(bitmap[0]) / 255.0
        let green = Double(bitmap[1]) / 255.0
        let blue = Double(bitmap[2]) / 255.0
        
        // Формула относительной яркости ITU-R BT.709
        let luminance = (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
        
        // Если яркость меньше 0.5 — фон тёмный, тексту требуется белый цвет
        let isDark = luminance < 0.55
        let color: Color = isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12)
        let shadowOpacity = isDark ? 0.6 : 0.2
        
        return (isDark, color, shadowOpacity)
    }
}
