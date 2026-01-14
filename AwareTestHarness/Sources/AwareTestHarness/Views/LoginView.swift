//
//  LoginView.swift
//  AwareTestHarness
//
//  Demonstrates: Text fields, secure fields, buttons, loading states, validation
//

import SwiftUI
import AwareCore

public struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var isAuthenticated: Bool = false
    @State private var errorMessage: String = ""
    @State private var emailFocused: Bool = false
    @State private var passwordFocused: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disabled(isLoading)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .disabled(isLoading)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoginEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isLoginEnabled || isLoading)

            if isAuthenticated {
                Text("✓ Authenticated")
                    .foregroundColor(.green)
                    .font(.headline)
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var isLoginEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    private func login() {
        // Clear previous errors
        errorMessage = ""
        isLoading = true

        // Simulate network request
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))

            // Validate
            if !email.contains("@") {
                errorMessage = "Invalid email address"
                isLoading = false
                return
            }

            if password.count < 6 {
                errorMessage = "Password must be at least 6 characters"
                isLoading = false
                return
            }

            // Success
            isAuthenticated = true
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}
