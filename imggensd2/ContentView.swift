//
//  ContentView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2022/12/05.
//

import SwiftUI

struct ContentView: View {
    @StateObject var imageGenerator = ImageGenerator()

    var body: some View {
        TabView {
            TextToImageView(imageGenerator: imageGenerator)
                .tabItem {
                    Image(systemName: "text.below.photo.fill")
                    Text("Text to Image")
                }
            ImageToImageView(imageGenerator: imageGenerator)
                .tabItem {
                    Image(systemName: "photo.stack.fill")
                    Text("Image to Image")
                }
        }
        .accentColor(.purple)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
