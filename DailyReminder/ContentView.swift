import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReminderViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    reminderListView
                }

                summaryView
            }
            .background(Color(hex: "F8F9FA"))
            .navigationTitle("每日提醒")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(Color(hex: "4A90D9"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                AddItemSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.requestNotificationPermission()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "95A5A6"))
            Text("点击 + 添加提醒事项")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "95A5A6"))
            Spacer()
        }
    }

    private var reminderListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    ReminderItemRow(item: item, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
    }

    private var summaryView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("已完成 \(viewModel.completedCount)/\(viewModel.totalCount) 项")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "95A5A6"))

                Spacer()

                Button(action: { viewModel.resetAllItems() }) {
                    Text("重置")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4A90D9"))
                }
            }
            .padding(.horizontal, 16)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "E0E0E0"))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color(hex: "7ED321"))
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }

    private var progress: CGFloat {
        guard viewModel.totalCount > 0 else { return 0 }
        return CGFloat(viewModel.completedCount) / CGFloat(viewModel.totalCount)
    }
}

struct ReminderItemRow: View {
    let item: ReminderItem
    @ObservedObject var viewModel: ReminderViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.toggleItem(item) }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(item.isCompleted ? Color(hex: "7ED321") : Color(hex: "95A5A6"))
            }

            Text(item.name)
                .font(.system(size: 16))
                .foregroundColor(item.isCompleted ? Color(hex: "95A5A6") : Color(hex: "2C3E50"))
                .strikethrough(item.isCompleted)

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteItem(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

struct AddItemSheet: View {
    @ObservedObject var viewModel: ReminderViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("提醒事项名称", text: $viewModel.newItemName)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color(hex: "F8F9FA"))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.newItemName = ""
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "95A5A6"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.addItem()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4A90D9"))
                    .fontWeight(.semibold)
                    .disabled(viewModel.newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}