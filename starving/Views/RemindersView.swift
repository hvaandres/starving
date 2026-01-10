//
//  RemindersView.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ReminderTimeCard: View {
    let time: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: isActive ? "bell.badge.fill" : "bell")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isActive ? Color.orange : .white.opacity(0.6))
            
            // Time
            Text(time)
                .font(.subheadline.weight(isActive ? .semibold : .medium))
                .foregroundColor(isActive ? .white : .white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 85, height: 85)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isActive ? 
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.6),
                                        Color.orange.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            :
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isActive ? 2 : 1
                        )
                )
        )
        .shadow(color: isActive ? Color.orange.opacity(0.3) : Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

struct AnimatedToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: isOn ? "bell.badge.fill" : "bell.slash")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isOn ? Color.orange : .white.opacity(0.5))
                
                // Label
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Toggle indicator
                ZStack {
                    Capsule()
                        .fill(isOn ? Color.orange.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .offset(x: isOn ? 10 : -10)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isOn ? [
                                        Color.orange.opacity(0.4),
                                        Color.orange.opacity(0.2)
                                    ] : [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isOn ? 2 : 1
                            )
                    )
            )
            .shadow(color: isOn ? Color.orange.opacity(0.25) : Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
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
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                            if !isRemindersOn {
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
                .padding(.bottom, 80)
            }
        }
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
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Daily Reminders")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Never forget your groceries with gentle daily notifications")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
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
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presetTimes, id: \.self) { time in
                        ReminderTimeCard(
                            time: time.formatted(date: .omitted, time: .shortened),
                            isActive: Calendar.current.compare(time, to: selectedDate, toGranularity: .minute) == .orderedSame
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = time
                            }
                        }
                    }
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditingTime.toggle()
                        }
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "clock.badge.plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Custom")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: 85, height: 85)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isEditingTime {
                VStack(spacing: 0) {
                    DatePicker("Select Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.orange.opacity(0.3),
                                            Color.orange.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color.orange.opacity(0.15), radius: 12, x: 0, y: 4)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Reminder Active")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange.opacity(0.8))
                    Text("Daily at \(formattedTime)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.8))
                    Text("Last updated \(Date(timeIntervalSince1970: lastModified).formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color.green.opacity(0.15), radius: 10, x: 0, y: 4)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("How It Works")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(icon: "bell.badge", text: "Get notified daily at your chosen time")
                InfoRow(icon: "checklist", text: "Never miss items from your shopping list")
                InfoRow(icon: "moon.zzz", text: "Gentle reminders, not intrusive")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
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
