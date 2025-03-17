//
//  BackgroundView.swift
//  Link
//
//  Created by Aaron Brown on 3/16/25.
//

import SwiftUI

struct BackgroundView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            content
        }
    }
}
