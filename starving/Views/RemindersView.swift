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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isActive ? [
                                Color.purple.opacity(0.6),
                                Color.purple.opacity(0.3),
                                Color.clear
                            ] : [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isActive ? .white : .white.opacity(0.7))
            }
            
            Text(time)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 100)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: isActive ? Color.purple.opacity(0.4) : Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
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
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: isOn ? [
                                    Color.purple.opacity(0.6),
                                    Color.purple.opacity(0.3),
                                    Color.clear
                                ] : [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isOn ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isOn ? Color.purple.opacity(0.3) : Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            Text("Daily Reminders")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Text("Set up gentle daily reminders to make sure you don't forget to purchase any of your groceries")
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
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.1),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 30
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "clock.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("Custom")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .frame(width: 100)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isEditingTime {
                DatePicker("Select Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.6),
                                    Color.purple.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                Text("Current Schedule")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Active")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.purple,
                                Color.purple.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text("Daily reminder scheduled for \(formattedTime)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Text("Last modified: \(Date(timeIntervalSince1970: lastModified).formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.6),
                                    Color.blue.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                Text("About Daily Reminders")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("This app helps you stay on top of grocery shopping with gentle reminders, keeping your routine organized and mindful.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
