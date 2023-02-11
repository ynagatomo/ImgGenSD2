//
//  TextToImageView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2023/02/11.
//

import SwiftUI

struct TextToImageView: View {
    static let prompt = "a photo of an astronaut riding a horse on mars"
    static let negativePrompt =
"""
lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits,
 cropped, worst quality, low quality, normal quality, jpeg artifacts, blurry, multiple legs, malformation
"""

    @ObservedObject var imageGenerator: ImageGenerator
    @State private var generationParameter =
        ImageGenerator.GenerationParameter(mode: .textToImage,
                                           prompt: prompt,
                                           negativePrompt: negativePrompt,
                                           guidanceScale: 8.0,
                                           seed: 1_000_000,
                                           stepCount: 20,
                                           imageCount: 1, disableSafety: false)
    var body: some View {
        ScrollView {
            VStack {
                Text("Text to image").font(.title3).bold().padding(6)
                Text("Sample App using apple/ml-stable-diffusion")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.bottom)

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

struct TextToImageView_Previews: PreviewProvider {
    static let imageGenerator = ImageGenerator()
    static var previews: some View {
        TextToImageView(imageGenerator: imageGenerator)
    }
}
