//
//  ListViewWithSearch.swift
//  AwareTestHarness
//
//  Demonstrates: Lists, search, filtering, selection state
//

import SwiftUI
import AwareCore

public struct ListViewWithSearch: View {
    @State private var searchText: String = ""
    @State private var selectedItems: Set<Int> = []

    private let items: [ListItem] = (0..<10).map { ListItem(id: $0, title: "Item \($0 + 1)") }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search items", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Results count
            Text("\(filteredItems.count) items")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // List
            List {
                ForEach(filteredItems) { item in
                    HStack {
                        Text(item.title)
                            .foregroundColor(selectedItems.contains(item.id) ? .blue : .primary)

                        Spacer()

                        if selectedItems.contains(item.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(item.id)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Computed Properties

    private var filteredItems: [ListItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: Int) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }
}

// MARK: - Supporting Types

private struct ListItem: Identifiable {
    let id: Int
    let title: String
}

#Preview {
    ListViewWithSearch()
}
