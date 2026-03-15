import Foundation
import SwiftUI
import UserNotifications

class ReminderViewModel: ObservableObject {
    @Published var items: [ReminderItem] = []
    @Published var showAddSheet = false
    @Published var newItemName = ""

    private let userDefaultsKey = "reminderItems"
    private let lastResetDateKey = "lastResetDate"

    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        items.count
    }

    var uncheckedItems: [ReminderItem] {
        items.filter { !$0.isCompleted }
    }

    init() {
        loadItems()
        checkDailyReset()
    }

    // MARK: - Data Persistence

    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ReminderItem].self, from: data) {
            items = decoded
        } else {
            // Default items
            items = [
                ReminderItem(name: "记账"),
                ReminderItem(name: "记录饮食"),
                ReminderItem(name: "手机清理")
            ]
            saveItems()
        }
    }

    func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    // MARK: - Daily Reset

    func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastReset = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            if today > lastResetDay {
                resetAllItems()
            }
        } else {
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
        }
    }

    func resetAllItems() {
        for index in items.indices {
            items[index].isCompleted = false
        }
        saveItems()
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
    }

    // MARK: - Item Management

    func addItem() {
        guard !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let item = ReminderItem(name: newItemName.trimmingCharacters(in: .whitespacesAndNewlines))
        items.append(item)
        newItemName = ""
        saveItems()
    }

    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func toggleItem(_ item: ReminderItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
            saveItems()
        }
    }

    func deleteItem(_ item: ReminderItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    // MARK: - Notifications

    func scheduleNotification() {
        NotificationManager.shared.scheduleEveningNotification(items: uncheckedItems)
    }

    func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                self.scheduleNotification()
            }
        }
    }
}