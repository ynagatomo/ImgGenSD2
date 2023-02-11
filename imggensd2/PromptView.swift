//
//  PromptView.swift
//  imggensd2
//
//  Created by Yasuhito Nagatomo on 2023/02/11.
//

import SwiftUI

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
            if parameter.mode == .imageToImage {
                Stepper(value: $parameter.strength, in: 0.0...0.9, step: 0.1) {
                    Text("Strength: \(parameter.strength, specifier: "%.1f") ")
                }
            }
        }
        .padding()
    }
}

struct PromptView_Previews: PreviewProvider {
    @State static var param = ImageGenerator.GenerationParameter(mode: .imageToImage,
                                                          prompt: "a prompt",
                                                          negativePrompt: "a negative prompt",
                                                          guidanceScale: 0.5,
                                                          seed: 1_000,
                                                          stepCount: 20,
                                                          imageCount: 1,
                                                          disableSafety: false,
                                                          strength: 0.5)
    static var previews: some View {
        PromptView(parameter: $param)
    }
}
