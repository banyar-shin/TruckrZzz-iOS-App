//
//  PulsateView.swift
//  TruckrZzz
//
//  Created by Banyar on 2/18/24.
//

import SwiftUI

struct PulsateView: View {
    @State private var show = false
    var delay: Double
    
    var body: some View {
        Circle()
            .frame(width: 1, height: 1)
            .foregroundColor(.red)
            .opacity(show ? 0 : 0.4)
            .scaleEffect(show ? 500 : 1)
            .animation(Animation.easeInOut(duration: 1))
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                    self.show = true
                }
            }
    }
}

#Preview {
    PulsateView(delay: 0.2)
}
