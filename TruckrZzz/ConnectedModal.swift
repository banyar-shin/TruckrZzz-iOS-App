//
//  ConnectedModal.swift
//  TruckrZzz
//
//  Created by Banyar on 2/18/24.
//

import SwiftUI

struct ModalView: View {
    var dataToShow: String

    var body: some View {
        // Customize your modal view here
        Text(dataToShow)
            .padding()
            .textSelection(.enabled)
        
        Button(action: {
            copyToClipboard(dataToShow)
        }) {
            Image(systemName: "doc.on.doc")
                .foregroundColor(.blue)
                .font(.title)
        }
        .padding()
    }
    
    private func copyToClipboard(_ text: String) {
            UIPasteboard.general.string = text
        }
}
