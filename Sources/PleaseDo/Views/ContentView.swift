import SwiftUI

/**
 * The main view for the Menu Bar popover.
 * Briges the SwiftUI interface into the native AppKit NSPopover container.
 */
public struct ContentView: View {
    /// Injected shared logic and state manager.
    @ObservedObject public var viewModel: TaskListViewModel
    
    /// Toggle for the 'Add Category' popover.
    @State private var showingAddCategory = false
    
    /// Temporary storage for new category name input.
    @State private var newCategoryName = ""
    
    /// Tracks the category pending confirmation for deletion.
    @State private var categoryToDelete: String? = nil
    
    /// Tracks the category pending name update.
    @State private var categoryToRename: String? = nil
    
    /// Buffer for the name input during a rename operation.
    @State private var pendingRenameValue: String = ""
    
    /// Tracks if the "Clear All Tasks" confirmation dialog is showing.
    @State private var showingClearAllConfirmation = false
    
    /// Namespace for shared geometry transitions (tab selection).
    @Namespace private var animation
    
    /**
     * Standard initializer for injecting the ViewModel.
     * - Parameter viewModel: The shared task state manager.
     */
    public init(viewModel: TaskListViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header Column: Tabs and Global Controls
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
                                        onDelete: {
                                            withAnimation {
                                                categoryToDelete = category
                                            }
                                        },
                                        onRename: {
                                            withAnimation {
                                                pendingRenameValue = category
                                                categoryToRename = category
                                            }
                                        }
                                    )
                                }
                                
                                if viewModel.canAddCategory {
                                    Button(action: {
                                        showingAddCategory.toggle()
                                    }) {
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
                                                let success = viewModel.addCategory(name: newCategoryName)
                                                if success {
                                                    newCategoryName = ""
                                                    showingAddCategory = false
                                                }
                                            },
                                            onCancel: {
                                                newCategoryName = ""
                                                showingAddCategory = false
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.vertical, 12)
                        }
                        
                        Spacer(minLength: 4)
                        
                        // Action Icons (Gear & Power)
                        HStack(spacing: 12) {
                            Menu {
                                Section("Display") {
                                    Toggle("Show Task Count in Tray", isOn: $viewModel.showPendingCount)
                                }
                                
                                Section("Category Actions") {
                                    Button(action: {
                                        withAnimation {
                                            viewModel.archiveCompletedInSelectedCategory()
                                        }
                                    }) {
                                        Label("Archive Completed", systemImage: "archivebox")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            showingClearAllConfirmation = true
                                        }
                                    }) {
                                        Label("Clear All Tasks", systemImage: "trash")
                                    }
                                }
                                
                                Section {
                                    Button(action: {
                                        NotificationCenter.default.post(name: .openArchiveWindow, object: nil)
                                    }) {
                                        Label("View Archive (\(viewModel.archiveCount))", systemImage: "archivebox.fill")
                                    }
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    if let url = URL(string: "https://pleasedo.io") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
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
                            
                            Button(action: {
                                NSApplication.shared.terminate(nil)
                            }) {
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
                
                   // Task List Section
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
                                               .padding(.horizontal, 8)
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
                
                // Quick Entry Area
                VStack(spacing: 0) {
                    Divider().opacity(0.5)
                    
                    HStack(spacing: 12) {
                        TextField("What's next?", text: $viewModel.newTaskTitle)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .onSubmit {
                                withAnimation(.spring()) {
                                    viewModel.addTask()
                                }
                            }
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.addTask()
                            }
                        }) {
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
            .blur(radius: (categoryToDelete != nil || categoryToRename != nil || showingClearAllConfirmation) ? 3 : 0)
            
            // Overlay: Clear All Confirmation
            if showingClearAllConfirmation {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { showingClearAllConfirmation = false }
                    }
                
                VStack(spacing: 16) {
                    Text("Clear All Tasks?")
                        .font(.headline)
                    
                    Text("Are you sure you want to delete all tasks in '\(viewModel.selectedCategory)'? This cannot be undone.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation { showingClearAllConfirmation = false }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        
                        Button("Clear All") {
                            withAnimation {
                                viewModel.clearAllInSelectedCategory()
                                showingClearAllConfirmation = false
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.red)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(Material.thick)
                .cornerRadius(12)
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Overlay: Delete Category Confirmation
            if let cat = categoryToDelete {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { categoryToDelete = nil }
                    }
                
                VStack(spacing: 16) {
                    Text("Delete Category?")
                        .font(.headline)
                    
                    Text("Are you sure you want to delete '\(cat)'? All associated tasks will be removed.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation { categoryToDelete = nil }
                        }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        
                        Button("Delete") {
                            withAnimation {
                                viewModel.deleteCategory(cat)
                                categoryToDelete = nil
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.red)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(Material.thick)
                .cornerRadius(12)
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Overlay: Rename Category Dialog
            if let cat = categoryToRename {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { categoryToRename = nil }
                    }
                
                VStack(spacing: 16) {
                    Text("Rename '\(cat)'")
                        .font(.headline)
                    
                    TextField("New name...", text: $pendingRenameValue)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            _ = viewModel.renameCategory(oldName: cat, newName: pendingRenameValue)
                            withAnimation { categoryToRename = nil }
                        }
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation { categoryToRename = nil }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        
                        Button("Save") {
                            withAnimation {
                                _ = viewModel.renameCategory(oldName: cat, newName: pendingRenameValue)
                                categoryToRename = nil
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(Material.thick)
                .cornerRadius(12)
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 460)
      }
   }

/**
 * A custom tab button for selecting categories.
 * Renders a capsule highlight for the active state and supports hover actions.
 */
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
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue)
                            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") { onRename() }
            if canDelete {
                Button("Delete", role: .destructive) { onDelete() }
            }
        }
        .onHover { isHovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                hover = isHovering
            }
        }
    }
}

/**
 * A popover-resident capture form for adding new category definitions.
 */
struct AddCategoryView: View {
    @Binding var newName: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Category")
                .font(.headline)
            
            TextField("e.g. Groceries", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .onSubmit(onAdd)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }
}

/**
 * A functional row component rendering a single task instance.
 * Handles user interactions for completion status, inline editing, and item removal.
 * Double-click the row to enter edit mode. Press Enter to save or Escape to cancel.
 * Clicking outside the row cancels the edit via the ViewModel's editingTaskId.
 */
public struct TaskRowView: View {
    public let task: TaskItem
    @ObservedObject public var viewModel: TaskListViewModel
    @State private var isHovering = false
    @FocusState private var isEditFieldFocused: Bool
    
    private var isEditing: Bool {
        viewModel.editingTaskId == task.id
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.toggleTask(task)
                }
            }) {
                 Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(task.isCompleted ? .blue : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(isEditing)

            if isEditing {
                TextField(task.title, text: $viewModel.editDraftTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .focused($isEditFieldFocused)
                    .onSubmit {
                        viewModel.commitCurrentEdit()
                    }
                    .onExitCommand {
                        viewModel.cancelCurrentEdit()
                    }
            } else {
                Text(task.title)
                      .font(.system(size: 14, weight: .regular, design: .default))
                      .strikethrough(task.isCompleted)
                      .foregroundColor(task.isCompleted ? .secondary : .primary)
                      .lineLimit(3)
                      .help(task.title)
            }
            
            Spacer()
            
            if !isEditing {
                if task.isCompleted {
                    Button(action: {
                        withAnimation {
                            viewModel.archiveTask(task)
                        }
                    }) {
                        Image(systemName: "archivebox")
                            .foregroundColor(.blue.opacity(0.7))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0)
                    .help("Archive")
                }
                
                Button(action: {
                    withAnimation {
                        viewModel.deleteTask(task)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEditing ? Color.blue.opacity(0.08) : (isHovering ? Color.secondary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .overlay(
            DoubleClickOverlay(onDoubleClick: {
                viewModel.startEditing(taskId: task.id)
            })
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onChange(of: isEditing) { editing in
            if editing {
                isEditFieldFocused = true
            }
        }
        .onChange(of: isEditFieldFocused) { focused in
            if !focused && isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if viewModel.editingTaskId == task.id {
                        viewModel.commitCurrentEdit()
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct DoubleClickOverlay: NSViewRepresentable {
    let onDoubleClick: () -> Void
    
    func makeNSView(context: Context) -> DoubleClickNSView {
        let view = DoubleClickNSView()
        view.onDoubleClick = onDoubleClick
        return view
    }
    
    func updateNSView(_ nsView: DoubleClickNSView, context: Context) {
        nsView.onDoubleClick = onDoubleClick
    }
}

class DoubleClickNSView: NSView {
    var onDoubleClick: (() -> Void)?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            onDoubleClick?()
        }
    }
}
