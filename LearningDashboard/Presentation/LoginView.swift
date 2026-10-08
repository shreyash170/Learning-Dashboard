import SwiftUI

struct LoginView: View {
    @State var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    fieldError(viewModel.emailError)
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                    fieldError(viewModel.passwordError)
                }

                if case .failed(let message) = viewModel.state {
                    Text(message).foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    Group {
                        if viewModel.isLoading { ProgressView().tint(.white) } else { Text("Log In") }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Welcome")
        }
    }

    @ViewBuilder
    private func fieldError(_ message: String?) -> some View {
        if let message { Text(message).font(.caption).foregroundStyle(.red) }
    }
}
