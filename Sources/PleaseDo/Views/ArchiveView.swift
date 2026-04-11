import SwiftUI

/**
 * Filterable view displaying all archived tasks.
 * Supports filtering by category, sorting by creation or archive date.
 */
public struct ArchiveView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    /// Currently selected category filter. "All" shows everything.
    @State private var selectedFilter: String = "All"
    
    /// Sort order for displayed archive items.
    @State private var sortOrder: SortOrder = .archivedNewest
    
    /// Available sort strategies.
    enum SortOrder: String, CaseIterable {
        case archivedNewest = "Archived (Newest)"
        case archivedOldest = "Archived (Oldest)"
        case createdNewest = "Created (Newest)"
        case createdOldest = "Created (Oldest)"
    }
    
    /**
     * Returns the filtered and sorted list of archived tasks.
     */
    private var displayedTasks: [TaskItem] {
        var result = viewModel.archivedTasks
        
        if selectedFilter != "All" {
            result = result.filter { $0.category == selectedFilter }
        }
        
        switch sortOrder {
        case .archivedNewest:
            result.sort { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
        case .archivedOldest:
            result.sort { ($0.archivedAt ?? .distantPast) < ($1.archivedAt ?? .distantPast) }
        case .createdNewest:
            result.sort { $0.createdAt > $1.createdAt }
        case .createdOldest:
            result.sort { $0.createdAt < $1.createdAt }
        }
        
        return result
    }
    
    /// Available filter options: "All" + each known category.
    private var filterOptions: [String] {
        var options = ["All"]
        let archiveCategories = Set(viewModel.archivedTasks.map { $0.category })
        options.append(contentsOf: archiveCategories.sorted())
        return options
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Archive")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("\(displayedTasks.count) items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Button(action: {
                    withAnimation { viewModel.showingArchive = false }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider().opacity(0.5)
            
            // Filter Bar
            HStack(spacing: 10) {
                // Category Filter
                Menu {
                    ForEach(filterOptions, id: \.self) { option in
                        Button(action: { selectedFilter = option }) {
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
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 12))
                        Text(selectedFilter)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
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
                            .font(.system(size: 12))
                        Text(sortOrder.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider().opacity(0.3)
            
            // Archive List
            if displayedTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No archived tasks")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(displayedTasks) { task in
                            ArchivedTaskRow(task: task, viewModel: viewModel)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/**
 * A single row displaying an archived task with metadata and a delete option.
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.blue.opacity(0.6))
                    .font(.system(size: 14))
                
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .strikethrough(true)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        viewModel.deleteArchivedTask(task)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            
            HStack(spacing: 12) {
                Label(task.category, systemImage: "tag")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue.opacity(0.7))
                
                if let archivedAt = task.archivedAt {
                    Label(Self.dateFormatter.string(from: archivedAt), systemImage: "archivebox")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Label(Self.dateFormatter.string(from: task.createdAt), systemImage: "calendar")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
