//
//  BackgroundView.swift
//  Link
//
//  Created by Aaron Brown on 3/16/25.
//

import SwiftUI

struct BackgroundView<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("AppBackground"),
                    Color("AppBackground").opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Add subtle pattern overlay
            Color("AppBackground")
                .opacity(0.1)
                .overlay(
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let spacing: CGFloat = 20
                            
                            for x in stride(from: 0, through: width, by: spacing) {
                                for y in stride(from: 0, through: height, by: spacing) {
                                    path.move(to: CGPoint(x: x, y: y))
                                    path.addLine(to: CGPoint(x: x + spacing/2, y: y + spacing/2))
                                }
                            }
                        }
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03), lineWidth: 1)
                    }
                )
                .ignoresSafeArea()
            
            content
        }
    }
}
