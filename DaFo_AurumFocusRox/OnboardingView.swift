//
//  OnboardingView.swift
//  AurumFocus
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var dataManagers: DataManagers
    @State private var currentStep = 0
    @State private var animationOffset: CGFloat = 0
    
    private let steps = [
        OnboardingStep(
            title: "Control your money",
            subtitle: "Track expenses, set budgets, and take charge of your financial future",
            icon: "creditcard"
        ),
        OnboardingStep(
            title: "Build strong habits",
            subtitle: "Create positive routines and track your progress week by week",
            icon: "chart.line.uptrend.xyaxis"
        ),
        OnboardingStep(
            title: "Plan & achieve",
            subtitle: "Organize tasks, set priorities, and accomplish your goals",
            icon: "list.bullet.rectangle"
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated background
            AurumTheme.backgroundGradient
                .ignoresSafeArea()
                .overlay(
                    // Subtle noise overlay
                    Rectangle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AurumTheme.goldAccent.opacity(0.05),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.3 + animationOffset * 0.1, y: 0.2),
                                startRadius: 50,
                                endRadius: 300
                            )
                        )
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animationOffset)
                )
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? AurumTheme.goldAccent : AurumTheme.dividers)
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.horizontal, AurumTheme.largePadding)
                .padding(.top, 20)
                
                Spacer()
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        OnboardingStepView(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
                
                Spacer()
                
                // Navigation buttons
                VStack(spacing: AurumTheme.padding) {
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                        }
                        .primaryButtonStyle()
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .secondaryButtonStyle()
                    } else {
                        Button("Start Now") {
                            completeOnboarding()
                        }
                        .primaryButtonStyle()
                        .scaleEffect(1.05)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatForever(autoreverses: true), value: currentStep)
                    }
                }
                .padding(.horizontal, AurumTheme.largePadding)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            animationOffset = 1
        }
    }
    
    private func completeOnboarding() {
        dataManagers.completeOnboarding()
    }
}

struct OnboardingStep {
    let title: String
    let subtitle: String
    let icon: String
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: AurumTheme.largePadding) {
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(AurumTheme.goldAccent)
                .scaleEffect(iconScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconScale)
            
            VStack(spacing: AurumTheme.padding) {
                // Title
                Text(step.title)
                    .font(.aurumTitle)
                    .foregroundColor(AurumTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text(step.subtitle)
                    .font(.aurumBody)
                    .foregroundColor(AurumTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.6).delay(0.2), value: textOpacity)
        }
        .padding(.horizontal, AurumTheme.largePadding)
        .onAppear {
            iconScale = 1.0
            textOpacity = 1.0
        }
    }
}

#Preview {
    OnboardingView(dataManagers: DataManagers())
}
