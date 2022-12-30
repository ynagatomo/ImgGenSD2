//
//  ContentView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2022/12/05.
//

import SwiftUI

struct ContentView: View {
    static let prompt = "a photo of an astronaut riding a horse on mars"
    static let negativePrompt =
"""
lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits,
 cropped, worst quality, low quality, normal quality, jpeg artifacts, blurry, multiple legs, malformation
"""

    @StateObject var imageGenerator = ImageGenerator()
    @State private var generationParameter =
        ImageGenerator.GenerationParameter(prompt: prompt,
                                           negativePrompt: negativePrompt,
                                           guidanceScale: 8.0,
                                           seed: 1_000_000,
                                           stepCount: 20,
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct PromptView: View {
    @Binding var parameter: ImageGenerator.GenerationParameter

    var body: some View {
        VStack {
            HStack { Text("Prompt:"); Spacer() }
            TextField("Prompt:", text: $parameter.prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack { Text("Negative Prompt:"); Spacer() }
            TextField("Negative Prompt:", text: $parameter.negativePrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper(value: $parameter.guidanceScale, in: 0.0...40.0, step: 0.5) {
                Text("Guidance scale: \(parameter.guidanceScale, specifier: "%.1f") ")
            }
            Stepper(value: $parameter.imageCount, in: 1...10) {
                Text("Image Count: \(parameter.imageCount)")
            }
            Stepper(value: $parameter.stepCount, in: 1...100) {
                Text("Iteration steps: \(parameter.stepCount)")
            }
            HStack { Text("Seed:"); Spacer() }
            TextField("Seed number (0 ... 4_294_967_295)",
                      value: $parameter.seed,
                      formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    if parameter.seed < 0 {
                        parameter.seed = 0
                    } else if parameter.seed > UInt32.max {
                        parameter.seed = Int(UInt32.max)
                    } else {
                        // do nothing
                    }
                }
        }
        .padding()
    }
}
