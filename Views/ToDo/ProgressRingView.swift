//
// ProgressRingView.swift
// FocalApp
//
// Индикатор выполнения задач в виде кольца прогресса (Progress Ring)
//

import SwiftUI

@MainActor
public struct ProgressRingView: View {
    let progress: Double // от 0.0 до 1.0
    let ratioText: String // Например "3/5"
    var ringSize: CGFloat = 44
    var lineWidth: CGFloat = 5
    
    public init(progress: Double, ratioText: String, ringSize: CGFloat = 44, lineWidth: CGFloat = 5) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.ratioText = ratioText
        self.ringSize = ringSize
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ZStack {
                // Задний фоновый круг
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: lineWidth)
                
                // Анимированная дуга заполнения
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        FocalTheme.gradientPrimary,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            }
            .frame(width: ringSize, height: ringSize)
            
            Text(ratioText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
