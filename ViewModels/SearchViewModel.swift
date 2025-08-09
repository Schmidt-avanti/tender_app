//
//  SearchViewModel.swift
//  TendersApp
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = Filters()
    @Published var results: [Tender] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var searchTask: Task<Void, Never>? = nil

    func search() {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil

        searchTask = Task {
            do {
                let data = try await APIClient.shared.searchTenders(filters: query)
                self.results = data
                self.isLoading = false
            } catch {
                if Task.isCancelled { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func reset() {
        query = Filters()
        results = []
        errorMessage = nil
    }
}
