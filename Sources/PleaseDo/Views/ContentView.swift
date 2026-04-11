import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TaskListViewModel()
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Tabs
            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // List of Tasks
            List {
                ForEach(viewModel.filteredTasks) { task in
                    TaskRowView(task: task, viewModel: viewModel)
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            // Input Area & Actions
            VStack {
                HStack {
                    TextField("Add a new task...", text: $viewModel.newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.addTask()
                        }
                    
                    Button(action: viewModel.addTask) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    Button("Clear Completed") {
                        viewModel.clearCompleted()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 300, height: 400)
    }
}

public struct TaskRowView: View {
    public let task: TaskItem
    @ObservedObject public var viewModel: TaskListViewModel
    @State private var isHovering = false
    
    public var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleTask(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            if isHovering {
                Button(action: {
                    viewModel.deleteTask(task)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
