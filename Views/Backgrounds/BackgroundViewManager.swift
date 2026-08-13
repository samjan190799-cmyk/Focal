//
// BackgroundViewManager.swift
// FocalApp
//
// Менеджер визуальных режимов фона: Full Bleed, Structured Banner (Top/Bottom) и Floating Object
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
public struct BackgroundViewManager: View {
    let mode: BackgroundMode
    let imageData: Data?
    let blurRadius: Double
    let overlayOpacity: Double
    
    // Свойства для интерактивного перемещения и трансформации плавающего объекта
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    
    public init(
        mode: BackgroundMode,
        imageData: Data?,
        blurRadius: Double = 0.0,
        overlayOpacity: Double = 0.3
    ) {
        self.mode = mode
        self.imageData = imageData
        self.blurRadius = blurRadius
        self.overlayOpacity = overlayOpacity
    }
    
    public var body: some View {
        Group {
            if let imageData, let image = imageFromData(imageData) {
                switch mode {
                case .fullBleed:
                    fullBleedView(image: image)
                case .structuredTop:
                    structuredBannerView(image: image, isTop: true)
                case .structuredBottom:
                    structuredBannerView(image: image, isTop: false)
                case .floating:
                    floatingObjectView(image: image)
                }
            } else {
                // При отсутствии изображения используется чистый адаптивный системный фон карточки
                Color.clear
            }
        }
    }
    
    // MARK: - Reusable Image Converter
    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
    
    // MARK: - 1. Full Bleed Mode
    @ViewBuilder
    private func fullBleedView(image: Image) -> some View {
        GeometryReader { proxy in
            image
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .blur(radius: blurRadius)
                .overlay(Color.black.opacity(overlayOpacity))
                .clipped()
        }
    }
    
    // MARK: - 2. Structured Layout (1/3 Banner Top/Bottom)
    @ViewBuilder
    private func structuredBannerView(image: Image, isTop: Bool) -> some View {
        VStack(spacing: 0) {
            if !isTop { Spacer() }
            
            image
                .resizable()
                .scaledToFill()
                .frame(maxHeight: 140)
                .overlay(Color.black.opacity(overlayOpacity * 0.5))
                .clipped()
                .cornerRadius(16)
                .padding(.horizontal, 12)
                .padding(isTop ? .top : .bottom, 12)
            
            if isTop { Spacer() }
        }
    }
    
    // MARK: - 3. Floating Object Mode
    @ViewBuilder
    private func floatingObjectView(image: Image) -> some View {
        ZStack {
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180, maxHeight: 180)
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
                .scaleEffect(scale)
                .rotationEffect(rotation)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                HapticManager.shared.impactLight()
                            },
                        MagnificationGesture()
                            .onChanged { val in
                                scale = lastScale * val
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
