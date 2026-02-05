//
//  TubeCityExtensionMainView.swift
//  TubeCityExtension
//
//  Created by Taylor Page on 1/22/26.
//

import SwiftUI

struct TubeCityExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup

    var body: some View {
        ZStack {
            // Clean light grey background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.9))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Output jack (left side) with vertical label
            HStack {
                HStack(spacing: 4) {
                    if let jackImage = NSImage(named: "jack") {
                        Image(nsImage: jackImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                    }
                    Text("OUTPUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(-90))
                        .fixedSize()
                }
                .offset(x: -21)
                Spacer()
            }
            .padding(.top, 20)

            // Input jack (right side) with vertical label
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("INPUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(-90))
                        .fixedSize()
                        .offset(x: -3)
                    if let jackImage = NSImage(named: "jack") {
                        Image(nsImage: jackImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                            .scaleEffect(x: -1, y: 1)
                            .offset(x: 3)
                    }
                }
                .offset(x: 18)
            }
            .padding(.top, 20)

            // Volume knob overlaid in top-right corner
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        ParameterKnob(param: parameterTree.global.outputvolume, size: 70)
                        Text("VOLUME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 12)
                Spacer()
            }

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 30)

                // Vacuum tube visualization (tube.png with signal-driven glow)
                tubeVisualization

                Spacer()
                    .frame(height: 10)

                // LED indicator
                ZStack {
                    Circle()
                        .fill(param.boolValue ? Color(red: 0.3, green: 0.35, blue: 0.32) : Color.green)
                        .frame(width: 20, height: 20)

                    Circle()
                        .stroke(Color.black.opacity(0.6), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    param.boolValue ? Color.clear : Color.white.opacity(0.6),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 10
                            )
                        )
                        .frame(width: 20, height: 20)

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.5), location: 0.0),
                                    .init(color: Color.white.opacity(0.2), location: 0.3),
                                    .init(color: Color.clear, location: 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .mask(
                            Circle()
                                .frame(width: 8, height: 8)
                                .offset(x: -3, y: -3)
                        )
                }
                .shadow(
                    color: param.boolValue ? .clear : .green.opacity(0.8),
                    radius: param.boolValue ? 0 : 6,
                    x: 0,
                    y: 0
                )

                Spacer()
                    .frame(height: 10)

                // Three tube style knobs
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        ParameterKnob(param: parameterTree.global.neutraltube, size: 52)
                        Text("NEUTRAL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                    }
                    VStack(spacing: 4) {
                        ParameterKnob(param: parameterTree.global.warmtube, size: 52)
                        Text("WARM")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                    }
                    VStack(spacing: 4) {
                        ParameterKnob(param: parameterTree.global.aggressivetube, size: 52)
                        Text("AGGRESSIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                    }
                }

                Spacer()

                // Centered stomp switch
                BypassButton(param: parameterTree.global.bypass)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)

            // TaylorAudio logo (bottom left corner)
            VStack {
                Spacer()
                HStack {
                    if let logoImage = NSImage(named: "TaylorAudio") {
                        Image(nsImage: logoImage)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .foregroundColor(.gray)
                            .opacity(0.7)
                    }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280, height: 480)
    }

    // MARK: - Tube Visualization

    private var tubeVisualization: some View {
        // Apply sqrt curve to lift quiet signals, plus a floor to keep tube slightly lit
        let rawLevel = Double(signalLevelParam.value)
        let level = rawLevel > 0 ? (0.15 + pow(rawLevel, 0.5) * 0.85) : 0.0

        // Reduce flicker intensity
        let flicker = min(Double(flickerLevelParam.value) * 0.9, 1.0)

        return ZStack {
            // Outer glow (wide, soft, yellow) — behind the tube image
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.75, blue: 0.10).opacity(level * 0.50),
                            Color(red: 0.90, green: 0.65, blue: 0.05).opacity(level * 0.25),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 38
                    )
                )
                .frame(width: 100, height: 160)
                .blur(radius: 8 + level * 5)

            // Inner glow core (tighter, brighter)
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.90, blue: 0.20).opacity(level * 0.75),
                            Color(red: 0.95, green: 0.75, blue: 0.10).opacity(level * 0.40),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 60, height: 100)
                .blur(radius: 3 + level * 3)

            // Base tube image
            if let tubeImage = NSImage(named: "tube") {
                Image(nsImage: tubeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 150)

                // Flicker overlay — yellow tint driven by fast-decay flickerLevel
                Image(nsImage: tubeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 150)
                    .colorMultiply(Color(red: 0.70, green: 0.55, blue: 0.05))
                    .opacity(flicker * 0.80)
            }
        }
        .frame(width: 120, height: 170)
    }

    // MARK: - Computed Properties

    var param: ObservableAUParameter {
        parameterTree.global.bypass
    }

    var signalLevelParam: ObservableAUParameter {
        parameterTree.global.signallevel
    }

    var flickerLevelParam: ObservableAUParameter {
        parameterTree.global.flickerlevel
    }
}
