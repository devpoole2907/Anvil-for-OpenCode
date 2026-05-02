import Foundation
import Observation

@MainActor
@Observable
final class ProviderStore {
    var providers: [ProviderInfo] = []
    var loading: Bool = false
    var lastError: OpencodeError?

    private let client: OpencodeClient

    init(client: OpencodeClient) {
        self.client = client
    }

    func refresh(directory: String) async {
        loading = true
        defer { loading = false }
        do {
            let response = try await client.providers(directory: directory)
            providers = response.providers.sorted()
        } catch {
            lastError = OpencodeError(error)
        }
    }

    func model(matching ref: ModelRef) -> ModelInfo? {
        providers.first { $0.id == ref.providerID }?
            .models.first { $0.id == ref.modelID }
    }

    func defaultModelRef() -> ModelRef? {
        guard let first = providers.first,
              let model = first.models.first
        else { return nil }
        return ModelRef(providerID: first.id, modelID: model.id)
    }
}
