import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    // Modal states
    @State private var categoryToDelete: String? = nil
    @State private var categoryToRename: String? = nil
    @State private var pendingRenameValue: String = ""
    
    // Smooth matched geometry effect for tab switching navigation
    @Namespace private var animation
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Elegant Header Background using Material
                VStack(spacing: 0) {
                    // Category Header Scroll
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
                                        .padding(8)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    Divider().opacity(0.5)
                }
                .background(Material.ultraThin)
                
                // List of Tasks
                List {
                    if viewModel.filteredTasks.isEmpty {
                        Text("No tasks yet. \nReady to conquer your day? 🚀")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(task: task, viewModel: viewModel)
                                .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
                
                // Input Area
                VStack(spacing: 12) {
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
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                viewModel.clearCompleted()
                            }
                        }) {
                            Text("Clear Completed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Material.ultraThin)
            }
            .blur(radius: (categoryToDelete != nil || categoryToRename != nil) ? 3 : 0) // Blur background when modal is open
            
            // Inline Deletion modal
            if let cat = categoryToDelete {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { categoryToDelete = nil }
                    }
                
                VStack(spacing: 16) {
                    Text("Delete Category?")
                        .font(.headline)
                    
                    Text("Are you sure you want to delete '\(cat)'? All tasks assigned to this category will be permanently removed.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation { categoryToDelete = nil }
                        }
                        .keyboardShortcut(.cancelAction)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.primary)
                        .buttonStyle(.plain)
                        
                        Button("Delete") {
                            withAnimation {
                                viewModel.deleteCategory(cat)
                                categoryToDelete = nil
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.red)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Material.thick)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Inline Rename Modal
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
                        .keyboardShortcut(.cancelAction)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.primary)
                        .buttonStyle(.plain)
                        
                        Button("Save") {
                            withAnimation {
                                _ = viewModel.renameCategory(oldName: cat, newName: pendingRenameValue)
                                categoryToRename = nil
                            }
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(pendingRenameValue.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Material.thick)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 460) // Slightly wider and taller for a premium feel
    }
}

// Custom Category Tab Button with matched geometry effect for elegant transitioning
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
                    .transition(.scale.combined(with: .opacity))
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
            Button("Rename") {
                onRename()
            }
            if canDelete {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            }
        }
        .onHover { isHovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                hover = isHovering
            }
        }
    }
}

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

public struct TaskRowView: View {
    public let task: TaskItem
    @ObservedObject public var viewModel: TaskListViewModel
    @State private var isHovering = false
    
    public var body: some View {
        HStack(spacing: 8) { // Reduced spacing for tighter checkbox padding
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.toggleTask(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 16, height: 16) // Slightly smaller box for elegance
                    .foregroundColor(task.isCompleted ? .blue : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .font(.system(size: 14, weight: .regular, design: .default))
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .lineLimit(2)
            
            Spacer()
            
            if isHovering {
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
                // small transition for the trash icon appearance
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, 6) // reduced vertical padding
        .padding(.horizontal, 8) // tightly hug the side
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
