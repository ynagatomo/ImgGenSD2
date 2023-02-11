//
//  ImageToImageView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2023/02/11.
//

import SwiftUI

struct ImageToImageView: View {
    static let prompt = "happy smile snow winter"
    static let negativePrompt =
"""
lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits,
 cropped, worst quality, low quality, normal quality, jpeg artifacts, blurry, multiple legs, malformation
"""
    static let startImageName = "sample1_512x512"

    @ObservedObject var imageGenerator: ImageGenerator
    @State private var generationParameter =
        ImageGenerator.GenerationParameter(mode: .imageToImage,
                                           prompt: prompt,
                                           negativePrompt: negativePrompt,
                                           guidanceScale: 8.0,
                                           seed: 1_000_000,
                                           stepCount: 20,
                                           imageCount: 1, disableSafety: false,
                                           startImage: UIImage(named: startImageName)?.cgImage,
                                           strength: 0.5)

    var body: some View {
        ScrollView {
            VStack {
                Text("Image to image").font(.title3).bold().padding(6)
                Text("Sample App using apple/ml-stable-diffusion")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.bottom)

                Image(ImageToImageView.startImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

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

struct ImageToImageView_Previews: PreviewProvider {
    static let imageGenerator = ImageGenerator()
    static var previews: some View {
        ImageToImageView(imageGenerator: imageGenerator)
    }
}
