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
    struct GenerationParameter {
        var prompt: String
        var negativePrompt: String
        var seed: Int
        var stepCount: Int
        var imageCount: Int
        var disableSafety: Bool
    }

    struct GeneratedImage: Identifiable {
        let id: UUID = UUID()
        let uiImage: UIImage
    }

    struct GeneratedImages {
        let prompt: String
        let negativePrompt: String
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
                if !ProcessInfo.processInfo.isiOSAppOnMac {
                    config.computeUnits = .cpuAndGPU
                }

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
                    let cgImages = try sdPipeline.generateImages(prompt: parameter.prompt,
                                                                 negativePrompt: parameter.negativePrompt,
                                                                 imageCount: parameter.imageCount,
                                                                 stepCount: parameter.stepCount,
                                                                 seed: UInt32(parameter.seed),
                                                                 disableSafety: parameter.disableSafety)
                    print("images were generated.")
                    let uiImages = cgImages.compactMap { image in
                        if let cgImage = image { return UIImage(cgImage: cgImage)
                        } else { return nil }
                    }
                    await self.setGeneratedImages(GeneratedImages(prompt: parameter.prompt,
                                                                  negativePrompt: parameter.negativePrompt,
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
