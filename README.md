# Gym Tracker - iOS Workout App

A comprehensive fitness tracking app built with SwiftUI that helps you monitor your gym progress. Create custom workout types, track sets, reps, and weights with beautiful progress visualization.

## Key Features

### Workout Management
- **Custom Workout Types**: Create and organize your own workout categories
- **Set Tracking**: Record weight, reps, and sets for each exercise
- **Custom Exercises**: Add your own exercises to any workout category
- **Workout History**: View and manage all your past workouts with swipe-to-delete

### Progress Analytics
- **Visual Charts**: Track weight progression for each exercise over time
- **Progress Summary**: See your highest weights and improvement metrics
- **Workout Stats**: Monitor total sets, exercises, and personal records

### User Experience
- **Modern UI**: Clean, intuitive interface following iOS design patterns
- **Tab Navigation**: Easy switching between Home, History, and Progress views
- **Edit Workouts**: Modify saved workouts after creation
- **Quick Actions**: Start new workouts with one tap

## Technical Architecture

### Built with SwiftUI
- **Framework**: SwiftUI for modern, declarative UI development
- **Target**: iOS170 native iOS design patterns
- **No Dependencies**: Pure SwiftUI implementation with no external libraries

### Data Management
- **Local Storage**: UserDefaults for persistent data storage
- **Data Models**: Codable structs for workout sessions, exercises, and sets
- **State Management**: SwiftUI's @State and @Binding for reactive UI updates

### App Structure
```
GymApp/
├── ContentView.swift          # Main app structure with TabView
├── HomeView                   # Dashboard with stats and quick actions
├── WorkoutHistoryView         # List of all workouts
├── ProgressView               # Charts and analytics
├── AddWorkoutView             # Workout creation interface
└── Data Models               # WorkoutSession, ExerciseSet, Set
```

### Key Components
- **TabView**: Three-tab navigation (Home, History, Progress)
- **NavigationView**: Hierarchical navigation for workout details
- **Sheet Presentations**: Modal views for adding workouts and exercises
- **Custom Charts**: Built-in SwiftUI progress visualization
- **Data Persistence**: Automatic saving of workouts and custom exercises

## Data Models

```swift
enum WorkoutType: String, CaseIterable, Codable {
    // Users can create custom workout types
    // Example types: "Upper", "Lower", "Push", "Pull", "Legs"
}

struct WorkoutSession: Identifiable, Codable {
    let type: WorkoutType
    let exercises: [ExerciseSet]
    let date: Date
    // Computed properties for totalSets, maxWeight
}

struct ExerciseSet: Identifiable, Codable {
    let name: String
    var sets: [Set]
}

struct Set: Codable {
    var weight: Int
    var reps: Int
}
```

## Features in Detail

### Home Dashboard
- Welcome message with motivation
- Quick stats cards showing weekly workouts and total sets
- Prominent Start New Workout" button with gradient styling
- Recent workouts carousel with workout cards

### Workout Creation
- Segmented picker for workout type selection
- Dynamic exercise picker with category-specific exercises
- Custom exercise creation with per-category organization
- Real-time set management with weight and rep inputs

### Progress Tracking
- Exercise-specific progression charts
- Weight improvement calculations
- Visual bar charts showing progression over time
- Summary statistics (highest weight, total improvement)

### Data Persistence
- Automatic saving of all workout data
- Custom exercises saved per workout category
- JSON encoding/decoding for data serialization
- UserDefaults for local storage

## Design Philosophy

The app follows iOS design principles with:
- **Consistency**: Standard iOS navigation patterns
- **Clarity**: Clear typography and visual hierarchy
- **Efficiency**: Quick access to common actions
- **Feedback**: Visual confirmation of user actions

Built for fitness enthusiasts who want a simple, effective way to track their gym progress without the complexity of larger fitness apps. 