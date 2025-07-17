import SwiftUI

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
            AddWorkoutView(workouts: $workouts, customExercises: $customExercises)
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

struct AddWorkoutView: View {
    @Binding var workouts: [WorkoutSession]
    @Binding var customExercises: [WorkoutType: [String]]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedWorkoutType: WorkoutType = .upper
    @State private var exercises: [ExerciseSet] = []
    @State private var showingExercisePicker = false
    @State private var showingCustomExerciseSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Workout Type Selector
                Picker("Workout Type", selection: $selectedWorkoutType) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Exercises List
                List {
                    ForEach(exercises.indices, id: \.self) { index in
                        ExerciseSetRow(exerciseSet: $exercises[index])
                    }
                    .onDelete(perform: deleteExercise)
                    
                    Button("Add Exercise") {
                        showingExercisePicker = true
                    }
                    
                    Button("Create Custom Exercise") {
                        showingCustomExerciseSheet = true
                    }
                    .foregroundColor(.orange)
                }
                
                // Save Button
                Button("Save Workout") {
                    saveWorkout()
                }
                .disabled(exercises.isEmpty)
                .buttonStyle(.borderedProminent)
                .padding()
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
                ExercisePickerView(exercises: $exercises, workoutType: selectedWorkoutType, customExercises: customExercises[selectedWorkoutType] ?? [])
            }
            .sheet(isPresented: $showingCustomExerciseSheet) {
                CreateCustomExerciseView(customExercises: $customExercises, exercises: $exercises, workoutType: selectedWorkoutType)
            }
        }
    }
    
    func deleteExercise(offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    func saveWorkout() {
        let workout = WorkoutSession(
            type: selectedWorkoutType,
            exercises: exercises,
            date: Date()
        )
        workouts.append(workout)
        saveWorkouts(workouts)
        dismiss()
    }
}

struct ExerciseSetRow: View {
    @Binding var exerciseSet: ExerciseSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exerciseSet.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(exerciseSet.sets.indices, id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        // Weight
                        HStack {
                            Text("Weight:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", value: $exerciseSet.sets[index].weight, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Reps
                        HStack {
                            Text("Reps:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", value: $exerciseSet.sets[index].reps, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                        }
                    }
                }
            }
            
            // Add Set Button
            Button("Add Set") {
                exerciseSet.sets.append(Set(weight: 0, reps: 0))
            }
            .font(.caption)
            .foregroundColor(.orange)
        }
        .padding(.vertical, 5)
    }
}

struct ExercisePickerView: View {
    @Binding var exercises: [ExerciseSet]
    let workoutType: WorkoutType
    let customExercises: [String]
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
        // Only add custom exercises for this type
        allExerciseNames.append(contentsOf: customExercises)
        // Filter out already added
        let addedExerciseNames = exercises.map { $0.name }
        return allExerciseNames.filter { exercise in
            !addedExerciseNames.contains(exercise)
        }
    }
    
    var body: some View {
        NavigationView {
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
                .navigationTitle("Add Exercise")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                List(availableExercises, id: \.self) { exercise in
                    Button(action: {
                        let newExercise = ExerciseSet(
                            name: exercise,
                            sets: [Set(weight: 0, reps: 0)]
                        )
                        exercises.append(newExercise)
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
    @Binding var exercises: [ExerciseSet]
    let workoutType: WorkoutType
    @Environment(\.dismiss) var dismiss
    @State private var exerciseName = ""
    
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
                    Button("Save & Add to Picker") {
                        if !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let exerciseNameTrimmed = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Add to custom exercises for this type only
                            var updated = customExercises[workoutType] ?? []
                            if !updated.contains(exerciseNameTrimmed) {
                                updated.append(exerciseNameTrimmed)
                                customExercises[workoutType] = updated
                                saveCustomExercisesByType(customExercises)
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
                            ExerciseSetRow(exerciseSet: $editedExercises[index])
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
    var sets: [Set]
}

struct Set: Codable {
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

#Preview {
    ContentView()
} 
