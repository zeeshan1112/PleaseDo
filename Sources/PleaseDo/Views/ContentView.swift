import SwiftUI

public struct ContentView: View {
    @ObservedObject public var viewModel: TaskListViewModel
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var categoryToDelete: String? = nil
    @State private var categoryToRename: String? = nil
    @State private var pendingRenameValue: String = ""
    @State private var showingClearAllConfirmation = false
    @Namespace private var animation
    
    public init(viewModel: TaskListViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                taskListSection
                quickEntrySection
            }
            .blur(radius: (categoryToDelete != nil || categoryToRename != nil || showingClearAllConfirmation) ? 3 : 0)
            
            if showingClearAllConfirmation { clearAllOverlay }
            if let cat = categoryToDelete { deleteCategoryOverlay(cat) }
            if let cat = categoryToRename { renameCategoryOverlay(cat) }
        }
        .frame(width: 320, height: 460)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryTabButton(
                                title: category,
                                isSelected: viewModel.selectedCategory == category,
                                canDelete: viewModel.categories.count > 1,
                                animation: animation,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedCategory = category
                                    }
                                },
                                onDelete: { withAnimation { categoryToDelete = category } },
                                onRename: { withAnimation { pendingRenameValue = category; categoryToRename = category } }
                            )
                        }
                        
                        if viewModel.canAddCategory {
                            Button(action: { showingAddCategory.toggle() }) {
                                Image(systemName: "plus")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.blue.opacity(0.4), radius: 3, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 4)
                            .popover(isPresented: $showingAddCategory, arrowEdge: .bottom) {
                                AddCategoryView(
                                    newName: $newCategoryName,
                                    onAdd: {
                                        if viewModel.addCategory(name: newCategoryName) {
                                            newCategoryName = ""
                                            showingAddCategory = false
                                        }
                                    },
                                    onCancel: { newCategoryName = ""; showingAddCategory = false }
                                )
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 12)
                }
                
                Spacer(minLength: 4)
                
                HStack(spacing: 12) {
                    Menu {
                        Section("Display") {
                            Toggle("Show Task Count in Tray", isOn: $viewModel.showPendingCount)
                        }
                        Section("Category Actions") {
                            Button(action: { withAnimation { viewModel.archiveCompletedInSelectedCategory() } }) {
                                Label("Archive Completed", systemImage: "archivebox")
                            }
                            Button(role: .destructive, action: { withAnimation { showingClearAllConfirmation = true } }) {
                                Label("Clear All Tasks", systemImage: "trash")
                            }
                        }
                        Section {
                            Button(action: { NotificationCenter.default.post(name: .openArchiveWindow, object: nil) }) {
                                Label("View Archive (\(viewModel.archiveCount))", systemImage: "archivebox.fill")
                            }
                        }
                        Divider()
                        Button(action: { if let url = URL(string: "https://pleasedo.io") { NSWorkspace.shared.open(url) } }) {
                            Label("About PleaseDo", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Settings & Actions")
                    
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Quit")
                }
                .padding(.trailing, 16)
            }
            Divider().opacity(0.5)
        }
        .background(Material.ultraThin)
    }
    
    // MARK: - Task List
    
    private var taskListSection: some View {
        VStack(spacing: 0) {
            if viewModel.filteredTasks.isEmpty {
                Text("No tasks yet. \nReady to conquer your day? 🚀")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(task: task, viewModel: viewModel)
                                .id(task.id)
                                .listRowSeparator(.hidden)
                        }
                        .onMove { source, destination in
                            viewModel.moveTask(from: source, to: destination)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: viewModel.filteredTasks.count) { _ in
                        if let topTask = viewModel.filteredTasks.first {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(topTask.id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Entry
    
    private var quickEntrySection: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)
            HStack(spacing: 12) {
                TextField("What's next?", text: $viewModel.newTaskTitle)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.7))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .onSubmit { withAnimation(.spring()) { viewModel.addTask() } }
                
                Button(action: { withAnimation(.spring()) { viewModel.addTask() } }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(viewModel.newTaskTitle.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .clipShape(Circle())
                        .shadow(color: viewModel.newTaskTitle.isEmpty ? .clear : Color.blue.opacity(0.4), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.newTaskTitle.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Material.ultraThin)
    }
    
    // MARK: - Overlays
    
    private var clearAllOverlay: some View {
        Group {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { showingClearAllConfirmation = false } }
            VStack(spacing: 16) {
                Text("Clear All Tasks?").font(.headline)
                Text("Are you sure you want to delete all tasks in '\(viewModel.selectedCategory)'? This cannot be undone.")
                    .font(.footnote).multilineTextAlignment(.center).padding(.horizontal, 8)
                HStack(spacing: 20) {
                    Button("Cancel") { withAnimation { showingClearAllConfirmation = false } }
                        .buttonStyle(.plain).padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2)).cornerRadius(6)
                    Button("Clear All") { withAnimation { viewModel.clearAllInSelectedCategory(); showingClearAllConfirmation = false } }
                        .buttonStyle(.plain).padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.red).cornerRadius(6).foregroundColor(.white)
                }
            }
            .padding(20).background(Material.thick).cornerRadius(12).padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func deleteCategoryOverlay(_ cat: String) -> some View {
        Group {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { categoryToDelete = nil } }
            VStack(spacing: 16) {
                Text("Delete Category?").font(.headline)
                Text("Are you sure you want to delete '\(cat)'? All associated tasks will be removed.")
                    .font(.footnote).multilineTextAlignment(.center).padding(.horizontal, 8)
                HStack(spacing: 20) {
                    Button("Cancel") { withAnimation { categoryToDelete = nil } }
                        .keyboardShortcut(.cancelAction).buttonStyle(.plain)
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2)).cornerRadius(6)
                    Button("Delete") { withAnimation { viewModel.deleteCategory(cat); categoryToDelete = nil } }
                        .keyboardShortcut(.defaultAction).buttonStyle(.plain)
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.red).cornerRadius(6).foregroundColor(.white)
                }
            }
            .padding(20).background(Material.thick).cornerRadius(12).padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func renameCategoryOverlay(_ cat: String) -> some View {
        Group {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { categoryToRename = nil } }
            VStack(spacing: 16) {
                Text("Rename '\(cat)'").font(.headline)
                TextField("New name...", text: $pendingRenameValue)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { _ = viewModel.renameCategory(oldName: cat, newName: pendingRenameValue); withAnimation { categoryToRename = nil } }
                HStack(spacing: 20) {
                    Button("Cancel") { withAnimation { categoryToRename = nil } }
                        .buttonStyle(.plain).padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2)).cornerRadius(6)
                    Button("Save") { withAnimation { _ = viewModel.renameCategory(oldName: cat, newName: pendingRenameValue); categoryToRename = nil } }
                        .keyboardShortcut(.defaultAction)
                        .disabled(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.plain).padding(.vertical, 6).padding(.horizontal, 12)
                        .background(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(6).foregroundColor(.white)
                }
            }
            .padding(20).background(Material.thick).cornerRadius(12).padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let canDelete: Bool
    let animation: Namespace.ID
    let action: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    @State private var hover = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
                if hover && canDelete && isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10)).foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6).padding(.horizontal, 14)
            .background(
                ZStack {
                    if isSelected { Capsule().fill(Color.blue).matchedGeometryEffect(id: "ACTIVETAB", in: animation) }
                    else { Capsule().fill(Color.secondary.opacity(0.1)) }
                }
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") { onRename() }
            if canDelete { Button("Delete", role: .destructive) { onDelete() } }
        }
        .onHover { isHovering in withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { hover = isHovering } }
    }
}

struct AddCategoryView: View {
    @Binding var newName: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Category").font(.headline)
            TextField("e.g. Groceries", text: $newName).textFieldStyle(.roundedBorder).frame(width: 180).onSubmit(onAdd)
            HStack {
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add", action: onAdd).keyboardShortcut(.defaultAction)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Drop Indicator

struct DropIndicatorLine: View {
    var body: some View {
        Capsule()
            .fill(Color.blue)
            .frame(height: 3)
            .padding(.horizontal, 8)
    }
}

// MARK: - Task Row

public struct TaskRowView: View {
    public let task: TaskItem
    @ObservedObject public var viewModel: TaskListViewModel
    @State private var isHovering = false
    @FocusState private var isEditFieldFocused: Bool
    
    private var isEditing: Bool { viewModel.editingTaskId == task.id }
    
    public var body: some View {
        HStack(spacing: 8) {
            checkBox
            if isEditing { editTextField } else { taskTitle }
            Spacer()
            if !isEditing { actionButtons }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(rowBackground)
        .overlay(rowBorder)
        .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering } }
        .onChange(of: isEditing) { if $0 { isEditFieldFocused = true } }
        .onChange(of: isEditFieldFocused) { if !$0 && isEditing { viewModel.commitCurrentEdit() } }
        .contentShape(Rectangle())
    }
    
    // MARK: Sub-views
    
    private var checkBox: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { viewModel.toggleTask(task) } }) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(task.isCompleted ? .blue : .secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .disabled(isEditing)
    }
    
    private var editTextField: some View {
        TextField(task.title, text: $viewModel.editDraftTitle)
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .regular, design: .default))
            .foregroundColor(.primary)
            .focused($isEditFieldFocused)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color(NSColor.controlBackgroundColor).opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blue.opacity(0.3), lineWidth: 1))
            .onSubmit { viewModel.commitCurrentEdit() }
            .onExitCommand { viewModel.cancelCurrentEdit() }
    }
    
    private var taskTitle: some View {
        Text(task.title)
            .font(.system(size: 14, weight: .regular, design: .default))
            .strikethrough(task.isCompleted)
            .foregroundColor(task.isCompleted ? .secondary : .primary)
            .lineLimit(3)
            .help(task.title)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 6) {
            Button(action: { viewModel.startEditing(taskId: task.id) }) {
                Image(systemName: "pencil")
                    .foregroundColor(.secondary.opacity(0.7))
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .help("Edit")
            
            if task.isCompleted {
                Button(action: { withAnimation { viewModel.archiveTask(task) } }) {
                    Image(systemName: "archivebox")
                        .foregroundColor(.blue.opacity(0.7))
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                .help("Archive")
            }
            
            Button(action: { withAnimation { viewModel.deleteTask(task) } }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isEditing ? Color.blue.opacity(0.06) : (isHovering ? Color.secondary.opacity(0.06) : Color.clear))
    }
    
    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isEditing ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
    }
}