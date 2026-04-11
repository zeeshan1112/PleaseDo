import SwiftUI

/**
 * Filterable, paginated view displaying all archived tasks.
 * Designed to be hosted in a standalone NSPanel window for maximum screen real estate.
 * Supports filtering by category, text search, and sorting by completion or creation date.
 */
public struct ArchiveView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    /// Currently selected category filter. "All" shows everything.
    @State private var selectedFilter: String = "All"
    
    /// Sort order for displayed archive items.
    @State private var sortOrder: SortOrder = .completedNewest
    
    /// Text search query for filtering by task title.
    @State private var searchText: String = ""
    
    /// Number of items currently visible (pagination cursor).
    @State private var visibleCount: Int = 50
    
    /// Controls the confirmation prompt for deleting all archived tasks.
    @State private var showingDeleteAllConfirmation = false
    
    /// Page size for "Load More" pagination.
    private let pageSize: Int = 50
    
    /// Available sort strategies.
    enum SortOrder: String, CaseIterable {
        case completedNewest = "Completed (Newest)"
        case completedOldest = "Completed (Oldest)"
        case createdNewest = "Created (Newest)"
        case createdOldest = "Created (Oldest)"
    }
    
    /**
     * Returns the fully filtered and sorted list of archived tasks.
     */
    private var allFilteredTasks: [TaskItem] {
        var result = viewModel.archivedTasks
        
        // Category filter
        if selectedFilter != "All" {
            result = result.filter { $0.category == selectedFilter }
        }
        
        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.title.lowercased().contains(query) }
        }
        
        // Sort
        switch sortOrder {
        case .completedNewest:
            result.sort { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        case .completedOldest:
            result.sort { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
        case .createdNewest:
            result.sort { $0.createdAt > $1.createdAt }
        case .createdOldest:
            result.sort { $0.createdAt < $1.createdAt }
        }
        
        return result
    }
    
    /// The paginated slice of filtered tasks currently visible.
    private var displayedTasks: [TaskItem] {
        Array(allFilteredTasks.prefix(visibleCount))
    }
    
    /// Whether there are more items to load.
    private var hasMoreItems: Bool {
        visibleCount < allFilteredTasks.count
    }
    
    /// Available filter options: "All" + each known category from archived tasks.
    private var filterOptions: [String] {
        var options = ["All"]
        let archiveCategories = Set(viewModel.archivedTasks.map { $0.category })
        options.append(contentsOf: archiveCategories.sorted())
        return options
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Compressed Header
            VStack(spacing: 10) {
                // Row 1: Title and Clear Action
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Task Archive")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text("\(allFilteredTasks.count) tasks")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !viewModel.archivedTasks.isEmpty {
                        Button(action: {
                            showingDeleteAllConfirmation = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear Archive")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog(
                            "Delete All Archived Tasks?",
                            isPresented: $showingDeleteAllConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Delete All Tasks", role: .destructive) {
                                withAnimation {
                                    viewModel.deleteAllArchivedTasks()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This action cannot be undone.")
                        }
                    }
                }
                
                // Row 2: Search and Filters (Unified Toolbar)
                HStack(spacing: 8) {
                    // Search Field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Category Filter
                    Menu {
                        ForEach(filterOptions, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                                visibleCount = pageSize
                            }) {
                                HStack {
                                    Text(option)
                                    if selectedFilter == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedFilter)
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    // Sort Order
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(action: { sortOrder = order }) {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 11))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Archive List
            if displayedTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    if searchText.isEmpty && selectedFilter == "All" {
                        Text("No archived tasks yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Completed tasks you archive will appear here.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    } else {
                        Text("No results found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Try adjusting your filters or search query.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedTasks) { task in
                            ArchivedTaskRow(task: task, viewModel: viewModel)
                            
                            if task.id != displayedTasks.last?.id {
                                Divider()
                                    .padding(.horizontal, 20)
                                    .opacity(0.4)
                            }
                        }
                        
                        // Pagination: Load More
                        if hasMoreItems {
                            VStack(spacing: 8) {
                                Divider().opacity(0.3)
                                
                                HStack {
                                    Text("Showing \(displayedTasks.count) of \(allFilteredTasks.count)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            visibleCount += pageSize
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("Load More")
                                                .font(.system(size: 12, weight: .semibold))
                                            Image(systemName: "arrow.down.circle")
                                                .font(.system(size: 12))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: searchText) { _ in
            visibleCount = pageSize
        }
    }
}

/**
 * A single row displaying an archived task with metadata and a delete option.
 * Designed for the spacious archive window layout.
 */
struct ArchivedTaskRow: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskListViewModel
    @State private var isHovering = false
    
    /// Compact date formatter for display.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.square.fill")
                .foregroundColor(.blue.opacity(0.5))
                .font(.system(size: 15))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .strikethrough(true)
                
                HStack(spacing: 14) {
                    Label(task.category, systemImage: "tag")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    if let completedAt = task.completedAt {
                        Label(Self.dateFormatter.string(from: completedAt), systemImage: "checkmark.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Label(Self.dateFormatter.string(from: task.createdAt), systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    viewModel.deleteArchivedTask(task)
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isHovering ? Color.secondary.opacity(0.04) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
