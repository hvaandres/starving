//
//  TodayView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//


//
//  TodayView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//


import SwiftUI
import SwiftData
import UserNotifications

struct Theme {
    static let primaryColor = Color.black
    static let secondaryColor = Color(.systemGray6)
    static let accentColor = Color.orange
    static let textColor = Color.primary
    static let subtitleColor = Color.secondary
}

struct ReminderTimeCard: View {
    let time: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.circle.fill")
                .font(.system(size: 24))
            Text(time)
                .font(.headline)
        }
        .padding()
        .frame(width: 100)
        .background(isActive ? Theme.primaryColor : Theme.secondaryColor)
        .foregroundColor(isActive ? .white : Theme.textColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AnimatedToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isOn.toggle()
            }
        }) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(isOn ? Theme.primaryColor : .gray)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: isOn ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(.white)
                    )
            }
            .padding()
            .background(Theme.secondaryColor)
            .cornerRadius(15)
        }
    }
}

struct RemindersView: View {
    @AppStorage("ReminderTime") private var reminderTime: Double = Date().timeIntervalSince1970
    @AppStorage("RemindersOn") private var isRemindersOn = false
    @AppStorage("LastModified") private var lastModified: Double = Date().timeIntervalSince1970
    
    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var isSettingsDialogShowing = false
    @State private var showingSuccessAlert = false
    @State private var isEditingTime = false
    
    private let presetTimes: [Date] = [
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
    ]
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        reminderToggle
                        
                        Group {
                            if isRemindersOn {
                                timeSelectionSection
                                statusCard
                                infoSection
                            } else {
                                infoSection
                                if !isRemindersOn {  // Explicit check
                                    VStack(alignment: .leading, spacing: 16) {
                                        Image("reminders")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .padding(.top, 16)
                                    }
                                }
                            }
                        }
                    }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear(perform: setupInitialState)
        .onChange(of: isRemindersOn, handleReminderToggle)
        .onChange(of: selectedDate, handleDateChange)
        .alert("Notifications Disabled", isPresented: $isSettingsDialogShowing) {
            Button("Go to Settings") { goToSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Reminders won't be sent unless Notifications are allowed. Please allow them in Settings.")
        }
        .alert("Reminder Set!", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You'll receive daily reminders at \(formattedTime)")
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Reminders")
                .font(.system(size: 34, weight: .bold))
            Text("Set up gentle daily reminders to make sure you don't forget to purchase any of your groceries")
                .font(.subheadline)
                .foregroundColor(Theme.subtitleColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var reminderToggle: some View {
        AnimatedToggle(isOn: $isRemindersOn, label: "Enable Daily Reminders")
    }
    
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Reminder Time")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presetTimes, id: \.self) { time in
                        ReminderTimeCard(
                            time: time.formatted(date: .omitted, time: .shortened),
                            isActive: Calendar.current.compare(time, to: selectedDate, toGranularity: .minute) == .orderedSame
                        )
                        .onTapGesture {
                            selectedDate = time
                        }
                    }
                    
                    Button(action: { isEditingTime = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.circle.fill")
                                .font(.system(size: 24))
                            Text("Custom")
                                .font(.headline)
                        }
                        .padding()
                        .frame(width: 100)
                        .background(Theme.secondaryColor)
                        .cornerRadius(12)
                    }
                }
            }
            
            if isEditingTime {
                DatePicker("Select Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding()
                    .background(Theme.secondaryColor)
                    .cornerRadius(12)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.and.waves.left.and.right.fill")
                    .foregroundColor(Theme.primaryColor)
                Text("Current Schedule")
                    .font(.headline)
                Spacer()
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Text("Daily reminder scheduled for \(formattedTime)")
                .font(.subheadline)
            
            Text("Last modified: \(Date(timeIntervalSince1970: lastModified).formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundColor(Theme.subtitleColor)
        }
        .padding()
        .background(Theme.secondaryColor)
        .cornerRadius(15)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Daily Reminders")
                .font(.headline)
            
            Text("This app helps you stay on top of grocery shopping with gentle reminders, keeping your routine organized and mindful.")
                .font(.subheadline)
                .foregroundColor(Theme.subtitleColor)
        }
        .padding()
        .background(Theme.secondaryColor)
        .cornerRadius(15)
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("reminders")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }
    // MARK: - Helper Functions
    
    private func setupInitialState() {
        selectedDate = Date(timeIntervalSince1970: reminderTime)
    }
    
    private func handleReminderToggle(oldValue: Bool, newValue: Bool) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    if newValue {
                        scheduleNotifications()
                        showingSuccessAlert = true
                    } else {
                        notificationCenter.removeAllPendingNotificationRequests()
                    }
                case .denied:
                    isRemindersOn = false
                    isSettingsDialogShowing = true
                case .notDetermined:
                    requestNotificationPermission()
                default:
                    break
                }
            }
        }
    }
    
    private func handleDateChange(oldValue: Date, newValue: Date) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
        
        if isRemindersOn {
            scheduleNotifications()
            showingSuccessAlert = true
        }
        
        reminderTime = selectedDate.timeIntervalSince1970
        lastModified = Date().timeIntervalSince1970
    }
    
    private func goToSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(appSettings) {
            UIApplication.shared.open(appSettings)
        }
    }
    
    private func requestNotificationPermission() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotifications()
                    showingSuccessAlert = true
                } else {
                    isRemindersOn = false
                    isSettingsDialogShowing = true
                }
                
                if let error = error {
                    print("Error requesting permission: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Daily Reminders"
        content.body = "Take a moment to do your shopping list. You've got this! 💪"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = Calendar.current.component(.hour, from: selectedDate)
        dateComponents.minute = Calendar.current.component(.minute, from: selectedDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    RemindersView()
}
