//
//  ContentView.swift
//  CH3
//
//  Created by Giulia Loffredo on 10/12/24.
//

import SwiftUI
import Combine
import AVFoundation
import AudioToolbox


class TimerViewModel: ObservableObject {
    @Published var remainingTime: Int = 0
    @Published var isTimerRunning = false
    @Published var isTimerPaused = false // Indica se il timer è in pausa
    
    private var timer: AnyCancellable? = nil
    
    func startTimer(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        // Inizia un nuovo timer solo se non è stato già avviato
        if !isTimerRunning && !isTimerPaused {
            remainingTime = (hours * 3600) + (minutes * 60) + seconds
        }
        
        isTimerRunning = true
        isTimerPaused = false
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.stopTimer()
                   self.announceCompletion()
                    self.playCompletionSound()
                }
            }
    }
    
    func pauseTimer() {
        isTimerRunning = false
        isTimerPaused = true
        timer?.cancel()
    }
    
    func stopTimer() {
        isTimerRunning = false
        isTimerPaused = false
        timer?.cancel()
        timer = nil
    }
    private func playCompletionSound() {
            // sound
            AudioServicesPlaySystemSound(1022)
        }
    
    func resetTimer() {
        stopTimer()
        remainingTime = 0
    }
    
    func formatTime() -> String {
        let hours = remainingTime / 3600
        let minutes = (remainingTime % 3600) / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // VoiceOver
    private func announceCompletion() {
        UIAccessibility.post(notification: .announcement, argument: "Timer is up.")
    }
}

struct TimerView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 15
    @State private var seconds: Int = 0
    
    var body: some View {
        VStack {
            // Title
            Text("Timer")
                .font(.largeTitle)
                .bold()
                .padding()
                .accessibilityLabel("Timer")
                .accessibilityAddTraits(.isHeader)
            
            // Time left
            Text(timerViewModel.formatTime())
                .font(.system(size: 48))
                .bold()
                //.padding()
                .accessibilityLabel("Time left")
                .accessibilityValue(timerViewModel.formatTime())
            
            // Picker
            if !timerViewModel.isTimerRunning && !timerViewModel.isTimerPaused {
                HStack {
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) { Text("\($0) hours") }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .accessibilityLabel("Select hours")
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { Text("\($0) min") }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .accessibilityLabel("Select minutes")
                    
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { Text("\($0) sec") }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .accessibilityLabel("Select seconds")
                }
            }
            
            // buttons to start, pause and resume
            HStack {
                // Pulsante per avviare, mettere in pausa o riprendere il timer
                Button(timerViewModel.isTimerRunning ? "Pause" : (timerViewModel.isTimerPaused ? "Resume" : "Start")) {
                    if timerViewModel.isTimerRunning {
                        timerViewModel.pauseTimer()
                    } else if timerViewModel.isTimerPaused {
                        timerViewModel.startTimer()
                    } else {
                        timerViewModel.startTimer(hours: hours, minutes: minutes, seconds: seconds)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(timerViewModel.isTimerRunning ? Color.orange : Color.green)
                .cornerRadius(8)
                .accessibilityLabel(timerViewModel.isTimerRunning ? "Pause timer" : (timerViewModel.isTimerPaused ? "Resume timer" : "Start timer"))
                .accessibilityHint(timerViewModel.isTimerRunning ? "Pause temporarly the timer." : "Start or resume the selected timer")
                
                // button to reset
                Button("Reset") {
                    timerViewModel.resetTimer()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .accessibilityLabel("Reset timer")
                .accessibilityHint("Start the timer from zero")
            }
        }
        //.padding()
    }
}



struct ContentView: View {
    @State private var selectedTab: Tab = .timer
    
    enum Tab {
        case timer
        case todo
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                        .accessibilityLabel("Timer Icon")
                    Text("Timer")
                        .accessibilityLabel("Timer Screen")
                }
                .tag(Tab.timer)
                .onAppear {announceTabChange("Timer")
                } // Annuncio per la scheda Time
            
            ToDoView()
                .tabItem {
                    Image(systemName: "list.bullet")
                        .accessibilityLabel("List Bullet Icon")
                    Text("To Do")
                        .accessibilityLabel("To Do List Screen")
                }
                .tag(Tab.todo)
                .onAppear {announceTabChange("To Do")
                } // Annuncio per la scheda To Do        }
        }
        .accessibilityElement(children: .contain) // Rende l'intero TabView accessibile
        
    }
    // Funzione per annunciare il cambio di scheda
    private func announceTabChange(_ tabName: String) {
        UIAccessibility.post(notification: .announcement, argument: "Selected screen: \(tabName)")
    }
}


// To Do
struct ToDoView: View {
    @State private var tasks: [Task] = [
        //Task(title: "Title 1"),
        //Task(title: "Title 2"),
       // Task(title: "Title 3"),
        //Task(title: "Title 4")
    ]
    @State private var newTaskTitle: String = "" // Campo di input per nuovi task
    
    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea().opacity(0.1)
            VStack {
                Text("To Do")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .accessibilityLabel("Task list")
                
                
                
                // task list
                List {
                    ForEach($tasks) { $task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                                .onTapGesture {
                                    task.isCompleted.toggle() // Toggle completamento task
                                }
                                .accessibilityLabel(task.isCompleted ? "Completed" : "Not completed")
                                .accessibilityHint("Touch to change the task status.")
                            
                            Text(task.title)
                                .strikethrough(task.isCompleted) // Linea sopra il testo se completato
                                .accessibilityLabel(task.title)
                                .accessibilityHint(task.isCompleted ? "This task is completed." : "This task is not completed.")
                        }
                    }
                    .onDelete(perform: deleteTask) // Aggiunta della funzione di swipe per eliminare task
                    .accessibilityLabel("Task list with deleting possibilities.")
                    .accessibilityHint("Swipe left to delete the task.")
                }
                
                
                HStack {
                    Button(action: addTask) {
                        Image(systemName: "plus.circle.fill")
                            .accessibilityLabel("Adding button")
                            .accessibilityHint("Add a new task to the list.")
                    }
                    TextField( "Add a new task", text: $newTaskTitle)
                        .accessibilityLabel("Text field for new task")
                        .accessibilityHint("Double-tap to type a new task.")
                }
                .padding()
            }
        }
    }
    
    // add a task
    func addTask() {
        guard !newTaskTitle.isEmpty else { return } // Non aggiunge task vuoti
        tasks.append(Task(title: newTaskTitle))
        newTaskTitle = "" // Resetta il campo di input
    }
    
    // delete a task
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

struct Task: Identifiable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}


struct task: Identifiable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




#Preview {
    ContentView()
}
