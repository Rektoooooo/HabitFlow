# HabitFlow

A beautiful, modern habit tracking app for iOS built with SwiftUI and SwiftData.

## Features

### Core Habit Tracking
- **Unlimited Habits** (Premium) - Track as many habits as you want
- **Multiple Habit Types** - Yes/No completion, numeric goals, and timed activities
- **Streak Tracking** - Stay motivated with current and best streak stats
- **Flexible Scheduling** - Daily, weekly, or custom day schedules

### Focus Sessions
- **Pomodoro-style Timer** - Dedicated focus time for any habit
- **Background Notifications** - Get notified when your session completes
- **Session History** - Track your total focus time and statistics

### Habit Stacking
- **Stack Builder** - Create chains of habits to build routines
- **Guided Flow** - Complete habits in sequence with a guided interface
- **Cue System** - Set triggers for when to start your stack

### Insights & Analytics
- **Weekly Insights** - AI-powered analysis of your habit patterns
- **Completion Trends** - Visualize your progress over time
- **Smart Suggestions** - Get personalized habit recommendations
- **Contribution Grid** - GitHub-style visualization of your consistency

### Widgets
- **Home Screen Widgets** - Multiple sizes (small, medium, large)
- **Lock Screen Widgets** - Quick glance at your progress
- **Habit History Widget** - See your completion history at a glance
- **Configurable** - Choose which habits to display

### Apple Watch App
- **Habit List** - View and complete habits from your wrist
- **Progress Ring** - See today's completion at a glance
- **Complications** - Add habit progress to your watch face
- **Sync** - Real-time sync with your iPhone

### Premium Features
- Unlimited habits (free tier: 5 habits)
- Apple Watch app
- All widget types
- Advanced insights
- Focus sessions
- Habit stacking
- Smart suggestions
- iCloud sync

## Tech Stack

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData with CloudKit sync
- **Watch Connectivity**: WatchConnectivity framework
- **Widgets**: WidgetKit with App Intents
- **In-App Purchases**: StoreKit 2
- **Health Integration**: HealthKit (optional)
- **Notifications**: UserNotifications

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+

## Architecture

```
HabitTracker/
├── App/                    # App entry point
├── Models/                 # SwiftData models
│   ├── Habit.swift
│   ├── HabitCompletion.swift
│   ├── HabitStack.swift
│   └── FocusSession.swift
├── Views/
│   ├── Main/              # Primary screens
│   ├── Habits/            # Habit CRUD views
│   ├── Insights/          # Analytics views
│   ├── Focus/             # Focus session UI
│   ├── Stacks/            # Habit stacking
│   ├── Onboarding/        # First-run experience
│   ├── Paywall/           # Premium subscription
│   └── Shared/            # Reusable components
├── Managers/              # Business logic
│   ├── NotificationManager.swift
│   ├── HealthKitManager.swift
│   ├── FocusSessionManager.swift
│   ├── InsightsEngine.swift
│   └── WatchConnectivityManager.swift
├── Store/                 # StoreKit integration
├── Theme/                 # App theming
└── Extensions/            # Swift extensions

HabitFlowWidget/           # iOS widget extension
HabitFlowWatch Watch App/  # watchOS companion app
HabitFlowWatchWidget/      # watchOS widget extension
```

## App Group

The app uses App Group `group.ic-servis.com.HabitTracker` for sharing data between:
- Main iOS app
- Widget extension
- Apple Watch app

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/Rektoooooo/HabitFlow.git
```

2. Open in Xcode
```bash
cd HabitFlow
open HabitTracker.xcodeproj
```

3. Configure signing
   - Select your development team
   - Update bundle identifiers if needed
   - Enable App Groups capability

4. Build and run

## StoreKit Configuration

The app includes a StoreKit configuration file (`Products.storekit`) for testing in-app purchases:
- `habittracker.premium.monthly` - Monthly subscription
- `habittracker.premium.yearly` - Yearly subscription
- `habittracker.premium.lifetime` - One-time purchase

## License

This project is available for personal use and learning purposes.

## Acknowledgments

Built with SwiftUI and modern Apple frameworks.
