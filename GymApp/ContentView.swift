import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var workouts: [WorkoutSession] = []
    @State private var showingAddWorkout = false
    @State private var customExercises: [WorkoutType: [String]] = [:]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(workouts: $workouts, showingAddWorkout: $showingAddWorkout, customExercises: $customExercises)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            WorkoutHistoryView(workouts: $workouts, customExercises: $customExercises)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
        }
        .accentColor(.orange)
        .sheet(isPresented: $showingAddWorkout) {
            WorkoutSetupView(workouts: $workouts, customExercises: $customExercises)
        }
        .onAppear {
            loadData()
        }
    }
    
    func loadData() {
        // Load workouts
        if let data = UserDefaults.standard.data(forKey: "savedWorkouts"),
           let decodedWorkouts = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workouts = decodedWorkouts
        }
        // Load custom exercises per category
        if let data = UserDefaults.standard.data(forKey: "customExercisesByType"),
           let decoded = try? JSONDecoder().decode([WorkoutType: [String]].self, from: data) {
            customExercises = decoded
        }
    }
}

struct HomeView: View {
    @Binding var workouts: [WorkoutSession]
    @Binding var showingAddWorkout: Bool
    @Binding var customExercises: [WorkoutType: [String]]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready to lift?")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your sets, reps, and weights")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Quick Stats
                    HStack(spacing: 15) {
                        StatCard(title: "This Week", value: "\(workouts.count)", subtitle: "Workouts", color: .blue)
                        StatCard(title: "Total Sets", value: "\(workouts.reduce(0) { $0 + $1.totalSets })", subtitle: "Completed", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(spacing: 15) {
                        Button(action: { showingAddWorkout = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Start New Workout")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Workouts
                    if !workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Workouts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(workouts.sorted(by: { $0.date > $1.date }).prefix(3)) { workout in
                                        NavigationLink(destination: WorkoutDetailView(workout: workout, workouts: $workouts, customExercises: $customExercises)) {
                                            WorkoutCard(workout: workout)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Gym Tracker")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WorkoutCard: View {
    let workout: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workout.type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(workout.totalSets) sets", systemImage: "dumbbell")
                Spacer()
                Label("\(workout.maxWeight) lbs", systemImage: "flame")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("\(workout.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct WorkoutHistoryView: View {
    @Binding var workouts: [WorkoutSession]
    @Binding var customExercises: [WorkoutType: [String]]
    @State private var showingCustomExerciseSheet = false
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutSession?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workouts.sorted(by: { $0.date > $1.date })) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout, workouts: $workouts, customExercises: $customExercises)) {
                        WorkoutRowView(workout: workout)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            workoutToDelete = workout
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Exercise") {
                        showingCustomExerciseSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingCustomExerciseSheet) {
                AddCustomExerciseView(customExercises: $customExercises)
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete,
                       let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                        workouts.remove(at: index)
                        saveWorkouts(workouts)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this \(workoutToDelete?.type.rawValue ?? "") workout? This action cannot be undone.")
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.totalSets) sets")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressView: View {
    @State private var allExercises: [String] = []
    @State private var selectedExercise: String = ""
    @State private var workouts: [WorkoutSession] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise Picker
                    if !allExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Exercise")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            Picker("Exercise", selection: $selectedExercise) {
                                ForEach(allExercises, id: \.self) { exercise in
                                    Text(exercise).tag(exercise)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Progression Chart
                    if !selectedExercise.isEmpty {
                        ProgressionChart(exerciseName: selectedExercise, allWorkouts: workouts)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadWorkouts()
                updateAllExercises()
                if selectedExercise.isEmpty, let first = allExercises.first {
                    selectedExercise = first
                }
            }
        }
    }
    
    func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: "savedWorkouts"),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workouts = decoded
        }
    }
    
    func updateAllExercises() {
        var exerciseSet = Swift.Set<String>()
        for workout in workouts {
            for exercise in workout.exercises {
                exerciseSet.insert(exercise.name)
            }
        }
        allExercises = Array(exerciseSet).sorted()
    }
}

struct WorkoutSetupView: View {
    @Binding var workouts: [WorkoutSession]
    @Binding var customExercises: [WorkoutType: [String]]
    @Environment(\.dismiss) var dismiss
    @State private var showingActiveWorkout = false
    
    @State private var selectedWorkoutType: WorkoutType = .upper
    @State private var selectedExercises: [String] = []
    @State private var showingExercisePicker = false
    @State private var showingCustomExerciseSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Plan Your Workout")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select your workout type and exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Workout Type Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    Picker("Workout Type", selection: $selectedWorkoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // Selected Exercises
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Selected Exercises")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(selectedExercises.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    if selectedExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No exercises selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Add Exercise' to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(selectedExercises, id: \.self) { exercise in
                                    HStack {
                                        Text(exercise)
                                            .font(.subheadline)
                                        Spacer()
                                        Button(action: {
                                            if let index = selectedExercises.firstIndex(of: exercise) {
                                                selectedExercises.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingExercisePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button(action: { showingCustomExerciseSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Custom Exercise")
                            Spacer()
                        }
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Start Workout Button
                Button(action: { showingActiveWorkout = true }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Start Workout")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(selectedExercises.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises, workoutType: selectedWorkoutType, customExercises: customExercises[selectedWorkoutType] ?? [])
            }
            .sheet(isPresented: $showingCustomExerciseSheet) {
                CreateCustomExerciseView(customExercises: $customExercises, selectedExercises: $selectedExercises, workoutType: selectedWorkoutType)
            }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(
                    workoutType: selectedWorkoutType,
                    exercises: selectedExercises,
                    workouts: $workouts,
                    customExercises: $customExercises,
                    dismiss: dismiss
                )
            }
        }
    }
}

struct ActiveWorkoutView: View {
    let workoutType: WorkoutType
    let exercises: [String]
    @Binding var workouts: [WorkoutSession]
    @Binding var customExercises: [WorkoutType: [String]]
    let dismiss: DismissAction
    
    @Environment(\.dismiss) var dismissSheet
    @State private var exerciseSets: [ExerciseSet] = []
    @State private var showingAddExercise = false
    @State private var showingCustomExercise = false
    @State private var showingSaveAlert = false
    @State private var isExitAlert = false
    // Remove currentExerciseIndex and navigation logic
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with workout info
                VStack(spacing: 8) {
                    Text(workoutType.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(exerciseSets.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack {
                            Text("\(exerciseSets.reduce(0) { $0 + $1.sets.count })")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                if exerciseSets.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Ready to start?")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Your exercises are ready. Start with any exercise and track your sets as you go.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    // Show all exercises as a scrollable list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(exerciseSets.indices, id: \.self) { index in
                                ActiveExerciseCard(
                                    exerciseSet: $exerciseSets[index],
                                    isCurrent: false // No current/selected logic
                                )
                            }
                        }
                        .padding()
                    }
                }
                // Bottom action bar
                if !exerciseSets.isEmpty {
                    VStack(spacing: 12) {
                        // Only Add Exercise and Finish Workout buttons
                        HStack(spacing: 12) {
                            Button(action: { showingAddExercise = true }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Exercise")
                                }
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                            Button(action: { isExitAlert = false; showingSaveAlert = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Finish Workout")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        isExitAlert = true; showingSaveAlert = true
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseWithCustomSheet(
                    workoutType: workoutType,
                    customExercises: $customExercises,
                    currentExerciseNames: exerciseSets.map { $0.name },
                    onExerciseSelected: { exercise in
                        addExercise(exercise)
                    },
                    onCreateCustom: {
                        showingCustomExercise = true
                    }
                )
            }
            .sheet(isPresented: $showingCustomExercise) {
                CreateCustomExerciseView(customExercises: $customExercises, selectedExercises: .constant([]), workoutType: workoutType, onExerciseCreated: { exercise in
                    addExercise(exercise)
                })
            }
            .alert("Finish Workout", isPresented: $showingSaveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Finish & Save") {
                    saveWorkout()
                }
                if isExitAlert {
                    Button("Exit Without Saving", role: .destructive) {
                        dismissSheet()
                        dismiss()
                    }
                }
            } message: {
                Text(isExitAlert ? "Do you want to finish and save this workout before exiting?" : "Do you want to finish and save this workout?")
            }
            .onAppear {
                initializeExercises()
            }
        }
    }
    
    func initializeExercises() {
        exerciseSets = exercises.map { exerciseName in
            ExerciseSet(name: exerciseName, sets: [])
        }
    }
    
    func addExercise(_ exerciseName: String) {
        let newExercise = ExerciseSet(name: exerciseName, sets: [])
        exerciseSets.append(newExercise)
        // currentExerciseIndex = exerciseSets.count - 1 // No longer needed
    }
    
    func saveWorkout() {
        // Filter out exercises with no sets
        let completedExercises = exerciseSets.filter { !$0.sets.isEmpty }
        
        if !completedExercises.isEmpty {
            let workout = WorkoutSession(
                type: workoutType,
                exercises: completedExercises,
                date: Date()
            )
            workouts.append(workout)
            saveWorkouts(workouts)
        }
        
        dismissSheet()
        dismiss()
    }
}

struct ActiveExerciseCard: View {
    @Binding var exerciseSet: ExerciseSet
    let isCurrent: Bool
    @State private var showingSetInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Text(exerciseSet.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
            }
            
            // Sets
            if exerciseSet.sets.isEmpty {
                Text("No sets yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(exerciseSet.sets.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Text("\(exerciseSet.sets[index].weight) lbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(exerciseSet.sets[index].reps) reps")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Add set button
            Button(action: { showingSetInput = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Set")
                }
                .foregroundColor(.orange)
                .font(.subheadline)
            }
        }
        .padding()
        .background(isCurrent ? Color.orange.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.orange : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingSetInput) {
            SetInputView(exerciseSet: $exerciseSet)
        }
    }
}

struct SetInputView: View {
    @Binding var exerciseSet: ExerciseSet
    @Environment(\.dismiss) var dismiss
    @State private var weight: Double = 0 // Change to Double for 2.5 increments
    @State private var reps: Int = 1
    @State private var lastWeight: Double = 0
    @State private var lastReps: Int = 1
    
    // Helper to get the previous set (if any)
    var previousSet: ExerciseSetEntry? {
        exerciseSet.sets.last
    }
    // Helper to get the previous weight (or a default)
    var previousWeight: Double {
        Double(previousSet?.weight ?? 45)
    }
    // Helper to get the quick add range (5 lb increments only)
    var quickAddWeights: [Double] {
        let base = previousWeight
        let minW = max(0, base - 20)
        let maxW = base + 20
        return stride(from: minW, through: maxW, by: 5).map { $0 }
    }
    // Dynamic picker options: all 5 lb increments + current weight if needed
    var weightPickerOptions: [Double] {
        var options = Set(stride(from: 0.0, through: 300.0, by: 5.0))
        options.insert(weight)
        return options.sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text(exerciseSet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    if let prev = previousSet {
                        Text("Previous: \(prev.weight) lbs x \(prev.reps) reps")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    } else {
                        Text("No previous set recorded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                // Input fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Weight (lbs)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: { weight = max(0, weight - 2.5) }) {
                                Text("-2.5")
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            Button(action: { weight = min(300, weight + 2.5) }) {
                                Text("+2.5")
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                        Picker("Weight", selection: $weight) {
                            ForEach(weightPickerOptions, id: \.self) { value in
                                Text(value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value))
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .onChange(of: weight) { newValue in
                            if newValue != lastWeight {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                lastWeight = newValue
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Picker("Reps", selection: $reps) {
                            ForEach(Array(1...50), id: \.self) { value in
                                Text("\(value)")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .onChange(of: reps) { newValue in
                            if newValue != lastReps {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                lastReps = newValue
                            }
                        }
                    }
                }
                .padding(.horizontal)
                Spacer()
                // Quick input buttons
                VStack(spacing: 12) {
                    Text("Quick Add")
                        .font(.headline)
                        .fontWeight(.semibold)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(quickAddWeights, id: \.self) { weightValue in
                            Button(action: {
                                weight = weightValue
                            }) {
                                Text(weightValue.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weightValue)) lbs" : String(format: "%.1f lbs", weightValue))
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                // Save button
                Button(action: saveSet) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Set")
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(weight == 0 || reps == 0)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Add Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveSet() {
        let newSet = ExerciseSetEntry(weight: Int(weight), reps: reps)
        exerciseSet.sets.append(newSet)
        dismiss()
    }
}

struct ExercisePickerView: View {
    @Binding var selectedExercises: [String]
    let workoutType: WorkoutType
    let customExercises: [String]
    @Environment(\.dismiss) var dismiss
    // Remove onExerciseSelected for planning phase
    
    @State private var tempSelected: Set<String> = []
    
    var availableExercises: [String] {
        var allExerciseNames: [String] = []
        switch workoutType {
        case .upper:
            allExerciseNames = ["Bench Press", "Pull ups", "Shoulder Press", "Preacher Curl", "Dips"]
        case .lower:
            allExerciseNames = ["Squats", "Hamstring Curls", "Leg Extension", "Calf Raises", "Freak Machines", "Decline Crunch"]
        case .push:
            allExerciseNames = ["Dips", "Shoulder Press", "Slight Incline DB Press", "Tricep Pushdown", "Overhead Press", "Chest Fly", "Lateral Raises"]
        case .pull:
            allExerciseNames = ["Preacher Curl", "Rows", "Pull ups", "Hammer Curl", "Forearm Curls", "Reverse Curls"]
        case .legs:
            allExerciseNames = ["Squats", "Hamstring Curls", "Leg Extension", "Calf Raises", "Freak Machines", "Ab Machine"]
        }
        allExerciseNames.append(contentsOf: customExercises)
        // Filter out already selected
        return allExerciseNames.filter { !selectedExercises.contains($0) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if availableExercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("All exercises added!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("You've added all available exercises for this workout type.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(availableExercises, id: \.self) { exercise in
                        Button(action: {
                            if tempSelected.contains(exercise) {
                                tempSelected.remove(exercise)
                            } else {
                                tempSelected.insert(exercise)
                            }
                        }) {
                            HStack {
                                Image(systemName: tempSelected.contains(exercise) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(.orange)
                                Text(exercise)
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                Button(action: {
                    selectedExercises.append(contentsOf: tempSelected)
                    dismiss()
                }) {
                    Text("Add Selected")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tempSelected.isEmpty ? Color.gray : Color.orange)
                        .cornerRadius(12)
                }
                .disabled(tempSelected.isEmpty)
                .padding()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempSelected = []
            }
        }
    }
}

struct AddCustomExerciseView: View {
    @Binding var customExercises: [WorkoutType: [String]]
    @Environment(\.dismiss) var dismiss
    @State private var exerciseName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Custom Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Exercise Name", text: $exerciseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Add Exercise") {
                    if !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // This function is no longer needed as customExercises is per-category
                        // customExercises.append(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines))
                        // saveCustomExercises(customExercises)
                        exerciseName = ""
                    }
                }
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                
                if !customExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Custom Exercises:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        List {
                            ForEach(customExercises.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                                Section(header: Text(category.rawValue)) {
                                    ForEach(customExercises[category] ?? [], id: \.self) { exercise in
                                        Text(exercise)
                                    }
                                    .onDelete(perform: deleteCustomExercise(for: category))
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Custom Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func deleteCustomExercise(for category: WorkoutType) -> (IndexSet) -> Void {
        return { offsets in
            var updated = customExercises[category] ?? []
            updated.remove(atOffsets: offsets)
            customExercises[category] = updated
            saveCustomExercisesByType(customExercises)
        }
    }
}

struct CreateCustomExerciseView: View {
    @Binding var customExercises: [WorkoutType: [String]]
    @Binding var selectedExercises: [String]
    let workoutType: WorkoutType
    @Environment(\.dismiss) var dismiss
    @State private var exerciseName = ""
    var onExerciseCreated: ((String) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Custom Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This exercise will be added to your \(workoutType.rawValue) workout and saved for future use.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Exercise Name", text: $exerciseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button("Save & Add to Workout") {
                        if !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let exerciseNameTrimmed = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Add to custom exercises for this type only
                            var updated = customExercises[workoutType] ?? []
                            if !updated.contains(exerciseNameTrimmed) {
                                updated.append(exerciseNameTrimmed)
                                customExercises[workoutType] = updated
                                saveCustomExercisesByType(customExercises)
                            }
                            
                            if let onExerciseCreated = onExerciseCreated {
                                onExerciseCreated(exerciseNameTrimmed)
                            } else {
                                selectedExercises.append(exerciseNameTrimmed)
                            }
                            
                            exerciseName = ""
                            dismiss()
                        }
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Create Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutDetailView: View {
    let workout: WorkoutSession
    @Binding var workouts: [WorkoutSession]
    @Binding var customExercises: [WorkoutType: [String]]
    @State private var isEditing = false
    @State private var editedExercises: [ExerciseSet] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Workout Header
                VStack(spacing: 10) {
                    Text(workout.type.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(workout.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(workout.totalSets)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(workout.exercises.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Edit Button
                Button(isEditing ? "Save Changes" : "Edit Workout") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                

                
                // Exercises List
                VStack(alignment: .leading, spacing: 15) {
                    Text("Exercises")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if isEditing {
                        ForEach(editedExercises.indices, id: \.self) { index in
                            ActiveExerciseCard(exerciseSet: $editedExercises[index], isCurrent: false)
                                .padding(.horizontal)
                        }
                    } else {
                        ForEach(workout.exercises) { exercise in
                            ExerciseDetailRow(exercise: exercise)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)

    }
    
    func startEditing() {
        editedExercises = workout.exercises
        isEditing = true
    }
    
    func saveChanges() {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = WorkoutSession(
                type: workout.type,
                exercises: editedExercises,
                date: workout.date
            )
            saveWorkouts(workouts)
        }
        isEditing = false
    }
}

struct ProgressionChart: View {
    let exerciseName: String
    let allWorkouts: [WorkoutSession]
    
    var progressionData: [(date: Date, weight: Int)] {
        var data: [(Date, Int)] = []
        
        for workout in allWorkouts.sorted(by: { $0.date < $1.date }) {
            for exercise in workout.exercises where exercise.name == exerciseName {
                let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
                if maxWeight > 0 {
                    data.append((workout.date, maxWeight))
                }
            }
        }
        
        return data
    }
    
    var body: some View {
        if progressionData.isEmpty {
            VStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No progression data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Complete more workouts with this exercise to see your progress")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // Chart Title
                Text("Weight Progression for \(exerciseName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // Chart area
                VStack(alignment: .leading, spacing: 8) {
                    // Y-axis with weight range
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .trailing, spacing: 0) {
                            if let maxWeight = progressionData.map({ $0.weight }).max() {
                                Text("\(maxWeight)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 30, height: 120)
                        
                        // Bars
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(progressionData.indices, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(
                                        width: 30,
                                        height: max(20, CGFloat(progressionData[index].weight) / CGFloat(progressionData.map { $0.weight }.max() ?? 1) * 120)
                                    )
                            }
                        }
                        .frame(height: 120)
                    }
                }
                
                // Summary
                if let maxWeight = progressionData.map({ $0.weight }).max() {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Highest Weight")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(maxWeight) lbs")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if progressionData.count > 1 {
                                    let firstWeight = progressionData.first?.weight ?? 0
                                    let improvement = maxWeight - firstWeight
                                    if improvement > 0 {
                                        Text("+\(improvement) lbs")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("No change")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("First time")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if progressionData.count > 1 {
                            HStack {
                                Text("Total workouts: \(progressionData.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Started: \(progressionData.first?.date ?? Date(), style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct ExerciseDetailRow: View {
    let exercise: ExerciseSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(exercise.sets.indices, id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Text("\(exercise.sets[index].weight) lbs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(exercise.sets[index].reps) reps")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Data Models
enum WorkoutType: String, CaseIterable, Codable {
    case upper = "Upper"
    case lower = "Lower"
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
}

struct WorkoutSession: Identifiable, Codable {
    var id = UUID()
    let type: WorkoutType
    let exercises: [ExerciseSet]
    let date: Date
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var maxWeight: Int {
        exercises.flatMap { $0.sets }.map { $0.weight }.max() ?? 0
    }
}

struct ExerciseSet: Identifiable, Codable {
    var id = UUID()
    let name: String
    var sets: [ExerciseSetEntry]
}

struct ExerciseSetEntry: Codable {
    var weight: Int
    var reps: Int
}

// Data Persistence Functions
func saveWorkouts(_ workouts: [WorkoutSession]) {
    if let encoded = try? JSONEncoder().encode(workouts) {
        UserDefaults.standard.set(encoded, forKey: "savedWorkouts")
    }
}

// Data Persistence for per-category custom exercises
func saveCustomExercisesByType(_ customExercises: [WorkoutType: [String]]) {
    if let encoded = try? JSONEncoder().encode(customExercises) {
        UserDefaults.standard.set(encoded, forKey: "customExercisesByType")
    }
}

// New sheet view for Add Exercise with Create Custom Exercise option
struct AddExerciseWithCustomSheet: View {
    let workoutType: WorkoutType
    @Binding var customExercises: [WorkoutType: [String]]
    var currentExerciseNames: [String]
    var onExerciseSelected: (String) -> Void
    var onCreateCustom: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var availableExercises: [String] {
        var allExerciseNames: [String] = []
        switch workoutType {
        case .upper:
            allExerciseNames = ["Bench Press", "Pull ups", "Shoulder Press", "Preacher Curl", "Dips"]
        case .lower:
            allExerciseNames = ["Squats", "Hamstring Curls", "Leg Extension", "Calf Raises", "Freak Machines", "Decline Crunch"]
        case .push:
            allExerciseNames = ["Dips", "Shoulder Press", "Slight Incline DB Press", "Tricep Pushdown", "Overhead Press", "Chest Fly", "Lateral Raises"]
        case .pull:
            allExerciseNames = ["Preacher Curl", "Rows", "Pull ups", "Hammer Curl", "Forearm Curls", "Reverse Curls"]
        case .legs:
            allExerciseNames = ["Squats", "Hamstring Curls", "Leg Extension", "Calf Raises", "Freak Machines", "Ab Machine"]
        }
        allExerciseNames.append(contentsOf: customExercises[workoutType] ?? [])
        // Filter out already added exercises
        return allExerciseNames.filter { !currentExerciseNames.contains($0) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List(availableExercises, id: \.self) { exercise in
                    Button(action: {
                        onExerciseSelected(exercise)
                        dismiss()
                    }) {
                        HStack {
                            Text(exercise)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.primary)
                }
                Button(action: {
                    dismiss()
                    onCreateCustom()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Exercise")
                    }
                    .foregroundColor(.orange)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 
