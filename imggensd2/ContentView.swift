//
//  ContentView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2022/12/05.
//

import SwiftUI

struct ContentView: View {
    @StateObject var imageGenerator = ImageGenerator()
    @State private var generationParameter =
        ImageGenerator.GenerationParameter(prompt: "a photo of an astronaut riding a horse on mars",
                                           seed: 100, stepCount: 20,
                                           imageCount: 1, disableSafety: false)
    var body: some View {
        ScrollView {
            VStack {
                Text("Stable Diffusion v2").font(.title).padding()

                PromptView(parameter: $generationParameter)
                    .disabled(imageGenerator.generationState != .idle)

                if imageGenerator.generationState == .idle {
                    Button(action: generate) {
                        Text("Generate").font(.title)
                    }.buttonStyle(.borderedProminent)
                } else {
                    ProgressView()
                }

                if let generatedImages = imageGenerator.generatedImages {
                    ForEach(generatedImages.images) {
                        Image(uiImage: $0.uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
        }
        .padding()
    }

    func generate() {
        imageGenerator.generateImages(generationParameter)
    }
}

//    struct ContentView_Previews: PreviewProvider {
//        static var previews: some View {
//            ContentView()
//        }
//    }

struct PromptView: View {
    @Binding var parameter: ImageGenerator.GenerationParameter

    var body: some View {
        VStack {
            TextField("Prompt:", text: $parameter.prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper(value: $parameter.imageCount, in: 1...10) {
                Text("Image Count: \(parameter.imageCount)")
            }
            Stepper(value: $parameter.stepCount, in: 1...100) {
                Text("Iteration steps: \(parameter.stepCount)")
            }
            Stepper(value: $parameter.seed, in: 0...10000) {
                Text("Seed: \(parameter.seed)")
            }
        }.padding()
    }
}
