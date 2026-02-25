// ConverterHubViewModel.swift
// FileFairy

import SwiftUI
import SwiftData
import Observation

@Observable
final class ConverterHubViewModel {

    // MARK: - State

    var searchText: String = ""
    var selectedCategory: ConversionCategory? = nil

    // MARK: - Computed

    var filteredTypes: [ConversionType] {
        var types = ConversionType.allCases

        if let category = selectedCategory {
            types = types.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            types = types.filter {
                $0.displayName.lowercased().contains(query) ||
                $0.subtitle.lowercased().contains(query)
            }
        }

        return types
    }

    var groupedTypes: [(category: ConversionCategory, types: [ConversionType])] {
        let grouped = Dictionary(grouping: filteredTypes) { $0.category }
        return ConversionCategory.allCases
            .compactMap { category in
                guard let types = grouped[category], !types.isEmpty else { return nil }
                return (category: category, types: types)
            }
    }

    // MARK: - Actions

    func selectCategory(_ category: ConversionCategory?) {
        withAnimation(.fairySnappy) {
            if selectedCategory == category {
                selectedCategory = nil
            } else {
                selectedCategory = category
            }
        }
    }

    func clearSearch() {
        searchText = ""
    }
}
