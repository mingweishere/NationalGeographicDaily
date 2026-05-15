import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 8
    @AppStorage("notificationMinute") private var notificationMinute = 0

    @State private var showPermissionDeniedAlert = false

    var body: some View {
        List {
            Section {
                Toggle("Daily Notification", isOn: toggleBinding)

                if notificationsEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: notificationTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text(notificationsEnabled
                     ? "You'll receive a daily reminder at the selected time."
                     : "Get a daily reminder when a new photo is available.")
            }

            Section("About") {
                LabeledContent("Source", value: "National Geographic")
                LabeledContent("Version", value: appVersion)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: notificationHour) { _, _ in rescheduleIfEnabled() }
        .onChange(of: notificationMinute) { _, _ in rescheduleIfEnabled() }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("To receive daily photo reminders, enable notifications for this app in iOS Settings.")
        }
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { enabled in
                if enabled {
                    Task { await enableNotifications() }
                } else {
                    notificationsEnabled = false
                    Task { await NotificationService.shared.cancelDailyNotification() }
                }
            }
        )
    }

    private var notificationTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: notificationHour, minute: notificationMinute)
                ) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                notificationHour = c.hour ?? 8
                notificationMinute = c.minute ?? 0
            }
        )
    }

    // MARK: - Helpers

    private func enableNotifications() async {
        let granted = await NotificationService.shared.requestAuthorization()
        if granted {
            notificationsEnabled = true
            await NotificationService.shared.scheduleDailyNotification(
                hour: notificationHour, minute: notificationMinute
            )
        } else {
            let status = await NotificationService.shared.authorizationStatus()
            if status == .denied { showPermissionDeniedAlert = true }
            notificationsEnabled = false
        }
    }

    private func rescheduleIfEnabled() {
        guard notificationsEnabled else { return }
        Task {
            await NotificationService.shared.scheduleDailyNotification(
                hour: notificationHour, minute: notificationMinute
            )
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
