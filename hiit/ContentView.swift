import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var workTime: Int = 30
    @State private var restTime: Int = 40
    @State private var rounds: Int = 3
    @State private var circuits: Int = 2
    @State private var currentTime: Int = 0
    @State private var isWorking: Bool = true
    @State private var currentRound: Int = 1
    @State private var currentCircuit: Int = 1
    @State private var timerRunning: Bool = false
    @State private var workoutComplete: Bool = false
    @State private var player: AVAudioPlayer?
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background Color
                (isWorking ? Color.blue : Color.green)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    if workoutComplete {
                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    } else {
                        // Timer Configuration Sliders
                        VStack(spacing: 20) {
                            sliderView(title: "Work Time", value: $workTime, range: 10...60, step: 1, isEnabled: !timerRunning)
                            sliderView(title: "Rest Time", value: $restTime, range: 5...60, step: 1, isEnabled: !timerRunning)
                            sliderView(title: "Rounds", value: $rounds, range: 1...10, step: 1, isEnabled: !timerRunning)
                            sliderView(title: "Circuits", value: $circuits, range: 1...5, step: 1, isEnabled: !timerRunning)
                        }
                        .padding(.horizontal, 20)

                        // Timer Display
                        VStack(spacing: 10) {
                            Text(isWorking ? "Work Time" : "Rest Time")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            Text("\(currentTime) seconds")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Round \(currentRound) of \(rounds)")
                                .foregroundColor(.white)
                            Text("Circuit \(currentCircuit) of \(circuits)")
                                .foregroundColor(.white)
                        }

                        // Control Buttons
                        HStack(spacing: 20) {
                            // Play/Pause Button
                            Button(action: {
                                if timerRunning {
                                    pauseTimer()
                                } else {
                                    startTimer()
                                }
                            }) {
                                Image(systemName: timerRunning ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                    .foregroundColor(.white)
                            }

                            // Stop/Reset Button
                            Button(action: resetTimer) {
                                Image(systemName: "stop.circle.fill")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // Custom Slider View
    @ViewBuilder
    func sliderView(title: String, value: Binding<Int>, range: ClosedRange<Double>, step: Double, isEnabled: Bool) -> some View {
        VStack {
            Text("\(title): \(value.wrappedValue)")
                .foregroundColor(.white)
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: range, step: step)
            .accentColor(.white) // Change slider color
            .frame(height: 40)   // Increase thickness
            .disabled(!isEnabled) // Disable slider if timer is running or paused
        }
    }

    func startTimer() {
        guard !workoutComplete else { return }

        // Initialize time if starting a new phase
        if currentTime == 0 {
            currentTime = isWorking ? workTime : restTime
        }

        timerRunning = true

        // Create a timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if currentTime > 0 {
                currentTime -= 1

                // Schedule a beep for 4, 3, 2, 1 seconds
                if [4, 3, 2, 1].contains(currentTime) {
                    playBeepSound()
                }
            } else {
                playBeepSound() // Beep at 0 when phase ends
                handleTimerEnd()
            }
        }
    }

    // Function to schedule beeps at 3, 2, and 1 seconds
    func scheduleCountdownBeeps() {
        let countdownTimes = [4, 3, 2]
        for time in countdownTimes {
            if currentTime >= time { // Only schedule beeps if currentTime allows
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentTime - time)) {
                    if currentTime == time && timerRunning { // Check if time matches and timer is running
                        playBeepSound()
                    }
                }
            }
        }
    }


    func pauseTimer() {
        timerRunning = false
        timer?.invalidate() // Stop the timer
    }

    func resetTimer() {
        timerRunning = false
        workoutComplete = false
        timer?.invalidate() // Stop and reset the timer
        currentTime = 0
        currentRound = 1
        currentCircuit = 1
        isWorking = true
    }

    func handleTimerEnd() {
        if isWorking {
            isWorking.toggle()
            currentTime = restTime
        } else {
            if currentRound < rounds {
                currentRound += 1
                isWorking.toggle()
                currentTime = workTime
            } else if currentCircuit < circuits {
                currentCircuit += 1
                currentRound = 1
                isWorking = true
                currentTime = workTime
            } else {
                workoutComplete = true
                timer?.invalidate()
            }
        }
    }

    func playBeepSound() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav") else {
            print("Beep sound file not found.")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            print("Playing beep sound.")
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
