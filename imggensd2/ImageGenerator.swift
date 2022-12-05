//
//  ImageGenerator.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2022/12/05.
//

import UIKit
import StableDiffusion

@MainActor
final class ImageGenerator: ObservableObject {
    struct GenerationParameter {
        var prompt: String
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
    private let sdpipeline: StableDiffusionPipeline

    init() {
        guard let path = Bundle.main.path(forResource: "CoreMLModels", ofType: nil, inDirectory: nil) else {
            fatalError("Fatal error: failed to find the CoreML models.")
        }
        let resourceURL = URL(fileURLWithPath: path)
        // TODO: move the pipeline creation to background task because it's heavy
        if let pipeline = try? StableDiffusionPipeline(resourcesAt: resourceURL) {
            sdpipeline = pipeline
        } else {
            fatalError("Fatal error: failed to create the Stable-Diffusion-Pipeline.")
        }
    }

    func setState(_ state: GenerationState) { // for actor isolation
        generationState = state
    }

    func setGeneratedImages(_ images: GeneratedImages) { // for actor isolation
        generatedImages = images
    }

    func generateImages(_ parameter: GenerationParameter) {
        guard generationState == .idle else { return }
        Task.detached(priority: .high) {
            await self.setState(.generating(progressStep: 0))
            do {
                //  generateImages(prompt: String, imageCount: Int = 1, stepCount: Int = 50, seed: Int = 0,
                //  disableSafety: Bool = false,
                //  progressHandler: (StableDiffusionPipeline.Progress) -> Bool = { _ in true }) throws -> [CGImage?]
                // TODO: use the progressHandler
                let cgImages = try self.sdpipeline.generateImages(prompt: parameter.prompt,
                                                                  imageCount: parameter.imageCount,
                                                                  stepCount: parameter.stepCount,
                                                                  seed: parameter.seed,
                                                                  disableSafety: parameter.disableSafety)
                print("images were generated.")
                let uiImages = cgImages.compactMap { image in
                    if let cgImage = image { return UIImage(cgImage: cgImage)
                    } else { return nil }
                }
                await self.setGeneratedImages(GeneratedImages(prompt: parameter.prompt,
                                                              imageCount: parameter.imageCount,
                                                              stepCount: parameter.stepCount,
                                                              seed: parameter.seed,
                                                              disableSafety: parameter.disableSafety,
                                           images: uiImages.map { uiImage in GeneratedImage(uiImage: uiImage) }))
            } catch {
                print("failed.")
            }
            await self.setState(.idle)
        }
    }
}
