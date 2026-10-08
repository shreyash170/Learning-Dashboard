//
//  Theme.swift
//  LearningDashboard
//
//  Created by SHREYASH GUPTA on 08/10/26.
//
import SwiftUI

enum Theme {
    static let accent = Color(red: 0.25, green: 0.38, blue: 0.95)
    static let background = Color(red: 0.96, green: 0.97, blue: 1.0)
}

extension View {
    func card() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ProgressRing: View {
    let value: Int
    var size: CGFloat = 56
    var track = Theme.accent.opacity(0.15)
    var color = Theme.accent

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: 8)
            Circle().trim(from: 0, to: Double(value) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(value)%")
                .font(.system(size: size * 0.26, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
