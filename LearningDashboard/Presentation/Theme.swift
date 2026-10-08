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
    }
}
