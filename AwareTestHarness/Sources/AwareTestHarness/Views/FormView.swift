//
//  FormView.swift
//  AwareTestHarness
//
//  Demonstrates: Multi-step forms, validation, progress tracking, state management
//

import SwiftUI
import AwareCore

public struct FormView: View {
    @State private var currentStep: Int = 1
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var validationErrors: [String] = []
    @State private var isComplete: Bool = false

    private let totalSteps = 3

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Registration Form")
                .font(.title)
                .bold()

            // Step indicator
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)

                    if step < totalSteps {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)

            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.gray)

            // Form fields
            VStack(alignment: .leading, spacing: 16) {
                if currentStep == 1 {
                    stepOneContent
                } else if currentStep == 2 {
                    stepTwoContent
                } else {
                    stepThreeContent
                }
            }
            .padding()

            // Validation errors
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(validationErrors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep > 1 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                            validationErrors = []
                        }
                    }
                    .padding()
                }

                Spacer()

                Button(currentStep == totalSteps ? "Submit" : "Next") {
                    handleNext()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()

            // Completion message
            if isComplete {
                Text("✓ Form submitted successfully!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    // MARK: - Step Content

    private var stepOneContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full Name")
                .font(.headline)

            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)

            Text("Please enter your full legal name")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var stepTwoContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.headline)

            TextField("Enter your email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            Text("We'll use this to contact you")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var stepThreeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.headline)

            TextField("Enter your phone", text: $phone)
                .textFieldStyle(.roundedBorder)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

            Text("Format: (555) 123-4567")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Actions

    private func handleNext() {
        validationErrors = []

        // Validate current step
        if currentStep == 1 {
            if name.isEmpty || name.count < 2 {
                validationErrors.append("Name must be at least 2 characters")
                return
            }
        } else if currentStep == 2 {
            if !email.contains("@") || !email.contains(".") {
                validationErrors.append("Please enter a valid email address")
                return
            }
        } else if currentStep == 3 {
            if phone.count < 10 {
                validationErrors.append("Please enter a valid phone number")
                return
            }
        }

        // Move to next step or submit
        if currentStep < totalSteps {
            withAnimation {
                currentStep += 1
            }
        } else {
            submitForm()
        }
    }

    private func submitForm() {
        // Simulate submission
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            isComplete = true
        }
    }
}

#Preview {
    FormView()
}
