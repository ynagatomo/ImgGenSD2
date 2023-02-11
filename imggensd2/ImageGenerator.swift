//
//  ImageGenerator.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2022/12/05.
//

import UIKit
import StableDiffusion
import CoreML

@MainActor
final class ImageGenerator: ObservableObject {
    enum GenerationMode {
        case textToImage, imageToImage
    }

    struct GenerationParameter {
        let mode: GenerationMode
        var prompt: String
        var negativePrompt: String
        var guidanceScale: Float
        var seed: Int
        var stepCount: Int
        var imageCount: Int
        var disableSafety: Bool
        var startImage: CGImage?
        var strength: Float = 1.0
    }

    struct GeneratedImage: Identifiable {
        let id: UUID = UUID()
        let uiImage: UIImage
    }

    struct GeneratedImages {
        let prompt: String
        let negativePrompt: String
        let guidanceScale: Float
        let imageCount: Int
        let stepCount: Int
        let seed: Int
        let disableSafety: Bool
        let images: [GeneratedImage]
    }

    enum GenerationState: Equatable {
        case idle
        case generating(progressStep: Int)
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.idle, idle): return true
            case (.generating(let step1), .generating(let step2)):
                if step1 == step2 { return true
                } else { return false }
            default:
                return false
            }
        }
    }

    @Published var generationState: GenerationState = .idle
    @Published var generatedImages: GeneratedImages?
    @Published var isPipelineCreated = false

    private var sdPipeline: StableDiffusionPipeline?

    init() {
    }

    func setState(_ state: GenerationState) { // for actor isolation
        generationState = state
    }

    func setPipeline(_ pipeline: StableDiffusionPipeline) { // for actor isolation
        sdPipeline = pipeline
        isPipelineCreated = true
    }

    func setGeneratedImages(_ images: GeneratedImages) { // for actor isolation
        generatedImages = images
    }

    // swiftlint:disable function_body_length
    func generateImages(_ parameter: GenerationParameter) {
        guard generationState == .idle else { return }
        Task.detached(priority: .high) {
            await self.setState(.generating(progressStep: 0))

            if await self.sdPipeline == nil {
                guard let path = Bundle.main.path(forResource: "CoreMLModels", ofType: nil, inDirectory: nil) else {
                    fatalError("Fatal error: failed to find the CoreML models.")
                }
                let resourceURL = URL(fileURLWithPath: path)

                let config = MLModelConfiguration()

                // [Note]
                // Specifying config.computeUnits is not necessary. Use the default.
                //
                // Specifying config.computeUnits = .cpuAndNeuralEngine will cause an internal fatal error on devices.
                // config.computeUnits = .cpuAndNeuralEngine
                //
                // Specifying config.computeUnits = .cpuAndGPU works on device with no reason.
                //     if !ProcessInfo.processInfo.isiOSAppOnMac {
                //         config.computeUnits = .cpuAndGPU
                //     }

                // reduceMemory option was added at v0.1.0
                // On iOS, the reduceMemory option should be set to true
                let reduceMemory = ProcessInfo.processInfo.isiOSAppOnMac ? false : true
                if let pipeline = try? StableDiffusionPipeline(resourcesAt: resourceURL,
                                                               configuration: config,
                                                               reduceMemory: reduceMemory) {
                    await self.setPipeline(pipeline)
                } else {
                    fatalError("Fatal error: failed to create the Stable-Diffusion-Pipeline.")
                }
            }

            if let sdPipeline = await self.sdPipeline {
                do {
                    // if you would like to use the progressHandler,
                    // please check the another repo - AR Diffusion Museum:
                    // https://github.com/ynagatomo/ARDiffMuseum
                    // It handles the progressHandler and displays the generating images step by step.

                    // apple/ml-stable-diffusion v0.2.0 changed the generateImages() API
                    //   to generateImages(configuration:progressHandler:)

                    var configuration = StableDiffusionPipeline.Configuration(prompt: parameter.prompt)
                    configuration.negativePrompt = parameter.negativePrompt
                    configuration.imageCount = parameter.imageCount
                    configuration.stepCount = parameter.stepCount
                    configuration.seed = UInt32(parameter.seed)
                    configuration.guidanceScale = parameter.guidanceScale
                    configuration.disableSafety = parameter.disableSafety

                    // [Note] generation mode: textToImage or imageToImage
                    //        when startingImage != nil AND strength < 1.0, imageToImage mode is selected
                    switch parameter.mode {
                    case .textToImage:
                        configuration.strength = 1.0
                    case .imageToImage:
                        configuration.startingImage = parameter.startImage
                        configuration.strength = parameter.strength
                    }

                    let cgImages = try sdPipeline.generateImages(configuration: configuration)

                    print("images were generated.")
                    let uiImages = cgImages.compactMap { image in
                        if let cgImage = image { return UIImage(cgImage: cgImage)
                        } else { return nil }
                    }
                    await self.setGeneratedImages(GeneratedImages(prompt: parameter.prompt,
                                                                  negativePrompt: parameter.negativePrompt,
                                                                  guidanceScale: parameter.guidanceScale,
                                                                  imageCount: parameter.imageCount,
                                                                  stepCount: parameter.stepCount,
                                                                  seed: parameter.seed,
                                                                  disableSafety: parameter.disableSafety,
                                    images: uiImages.map { uiImage in GeneratedImage(uiImage: uiImage) }))
                } catch {
                    print("failed to generate images.")
                }
            }

            await self.setState(.idle)
        }
    }
}
