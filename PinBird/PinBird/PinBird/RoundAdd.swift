//
//  RoundAdd.swift
//  PinBird
//
//  Created by egsango on 24/02/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GolfRoundView: View {
    @State private var courseName: String = ""
    @State private var slopeRating: String = ""
    @State private var currentHole: Int = 0
    @State private var holeData: [Hole] = Array(repeating: Hole(), count: 18)
    @State private var showScorecard = false
    @State private var eloChange: Double = 0.0
    @State private var currentElo: Double = 300.0

    var body: some View {
        NavigationView {
            if showScorecard {
                ScorecardView(
                    holeData: holeData,
                    courseName: courseName,
                    eloChange: eloChange,
                    currentElo: currentElo
                ) {
                    saveStatistics()
                }
            } else if currentHole == 0 {
                CourseSetupView(courseName: $courseName, slopeRating: $slopeRating, startRound: {
                    currentHole = 1
                    fetchCurrentElo()
                })
            } else {
                HoleEntryView(
                    hole: $holeData[currentHole - 1],
                    holeNumber: currentHole,
                    totalScore: calculateTotalScore(),
                    nextHole: {
                        if currentHole < 18 {
                            currentHole += 1
                        } else {
                            calculateEloChange()
                            showScorecard = true
                        }
                    },
                    previousHole: {
                        if currentHole > 1 {
                            currentHole -= 1
                        }
                    }
                )
            }
        }
    }
    
    private func fetchCurrentElo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
        
        ref.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.currentElo = data["elo"] as? Double ?? 300.0
            }
        }
    }
    
    private func calculateEloChange() {
        let totalStrokes = holeData.reduce(0) { $0 + $1.score }
        let totalPar = holeData.reduce(0) { $0 + $1.par }
        let totalPutts = holeData.reduce(0) { $0 + $1.putts }
        let greensHit = holeData.filter { $0.missedGreen == .hitGreen }.count
        let fairwaysHit = holeData.filter { $0.missDirection == .center }.count
        let totalToPar = totalStrokes - totalPar
        
        let baseEloChange: Double = 20.0
        let puttWeight: Double = 0.7
        let girWeight: Double = 1.0
        let fairwayWeight: Double = 0.6
        
        let averagePuttsPerHole = Double(totalPutts) / 18.0
        let puttFactor = (2.0 - averagePuttsPerHole) * puttWeight
        
        let girPercentage = Double(greensHit) / 18.0
        let girFactor = (girPercentage - 0.5) * girWeight
        
        let fairwayPercentage = Double(fairwaysHit) / 14.0
        let fairwayFactor = (fairwayPercentage - 0.5) * fairwayWeight
        
        var scoreBonus = 0.0
        if totalToPar < 0 {
            scoreBonus = 0.8
        } else if totalToPar <= 9 {
            scoreBonus = 0.4
        } else if totalToPar <= 18 {
            scoreBonus = 0.2
        }
        
        let performanceFactor = puttFactor + girFactor + fairwayFactor + scoreBonus
        let calculatedEloChange = baseEloChange * performanceFactor
        
        eloChange = max(-35.0, min(35.0, calculatedEloChange))
    }

    private func calculateTotalScore() -> Int {
        let totalStrokes = holeData.reduce(0) { $0 + $1.score }
        let totalPar = holeData.reduce(0) { $0 + $1.par }
        return totalStrokes - totalPar
    }

    private func saveStatistics() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)

        let totalPutts = holeData.reduce(0) { $0 + $1.putts }
        let greensHit = holeData.filter { $0.missedGreen == .hitGreen }.count
        let fairwaysHit = holeData.filter { $0.missDirection == .center }.count
        let greenMissLeft = holeData.filter { $0.missedGreen == .left }.count
        let greenMissRight = holeData.filter { $0.missedGreen == .right }.count
        let greenMissShort = holeData.filter { $0.missedGreen == .short }.count
        let greenMissLong = holeData.filter { $0.missedGreen == .long }.count
        let fairwayMissLeft = holeData.filter { $0.missDirection == .left }.count
        let fairwayMissRight = holeData.filter { $0.missDirection == .right }.count
        let par3s = holeData.filter { $0.par == 3 }
        let par4s = holeData.filter { $0.par == 4 }
        let par5s = holeData.filter { $0.par == 5 }

        let totalStrokes = holeData.reduce(0) { $0 + $1.score }
        let totalPar = holeData.reduce(0) { $0 + $1.par }
        
        // Store the total strokes for the round, not the average per hole
        let roundScore = totalStrokes

        let stats = RoundStats(
            averagePutts: Double(totalPutts), // Store total putts for the round, not per hole
            greensInRegulation: Double(greensHit) / 18.0,
            fairwayHitPercentage: Double(fairwaysHit) / 18.0,
            greenMissLeftPercentage: Double(greenMissLeft) / 18.0,
            greenMissRightPercentage: Double(greenMissRight) / 18.0,
            greenMissShortPercentage: Double(greenMissShort) / 18.0,
            greenMissLongPercentage: Double(greenMissLong) / 18.0,
            fairwayMissLeftPercentage: Double(fairwayMissLeft) / 18.0,
            fairwayMissRightPercentage: Double(fairwayMissRight) / 18.0,
            par3Average: par3s.isEmpty ? 0 : Double(par3s.reduce(0) { $0 + $1.score }) / Double(par3s.count),
            par4Average: par4s.isEmpty ? 0 : Double(par4s.reduce(0) { $0 + $1.score }) / Double(par4s.count),
            par5Average: par5s.isEmpty ? 0 : Double(par5s.reduce(0) { $0 + $1.score }) / Double(par5s.count),
            averageScore: Double(roundScore)
        )

        ref.getDocument { snapshot, error in
            var roundsPlayed = 0
            var oldStats: [String: Double] = [:]
            var previousTotalScore: Double = 0

            if let data = snapshot?.data() {
                roundsPlayed = data["roundsPlayed"] as? Int ?? 0
                for key in RoundStats.keys {
                    oldStats[key] = data[key] as? Double ?? 0
                }
                
                // If we already have an average score, calculate the total accumulated score
                if let currentAvg = data["averageScore"] as? Double {
                    previousTotalScore = currentAvg * Double(roundsPlayed)
                }
            }

            let newElo = self.currentElo + self.eloChange

            var updated: [String: Any] = [
                "roundsPlayed": roundsPlayed + 1,
                "elo": newElo,
                "lastEloChange": self.eloChange
            ]

            func avg(_ key: String, _ newValue: Double) -> Double {
                ((oldStats[key] ?? 0) * Double(roundsPlayed) + newValue) / Double(roundsPlayed + 1)
            }

            for key in RoundStats.keys {
                if key == "averageScore" || key == "averagePutts" {
                    // Special handling for averageScore and averagePutts - calculate true average of all rounds
                    let previousTotal = (oldStats[key] ?? 0) * Double(roundsPlayed)
                    let newValue = stats[keyPath: RoundStats.keyPaths[key]!]
                    let newTotal = previousTotal + newValue
                    updated[key] = newTotal / Double(roundsPlayed + 1)
                } else {
                    let newValue = stats[keyPath: RoundStats.keyPaths[key]!]
                    updated[key] = avg(key, newValue)
                }
            }

            ref.setData(updated, merge: true)
        }
    }
}

struct RoundStats {
    var averagePutts: Double
    var greensInRegulation: Double
    var fairwayHitPercentage: Double
    var greenMissLeftPercentage: Double
    var greenMissRightPercentage: Double
    var greenMissShortPercentage: Double
    var greenMissLongPercentage: Double
    var fairwayMissLeftPercentage: Double
    var fairwayMissRightPercentage: Double
    var par3Average: Double
    var par4Average: Double
    var par5Average: Double
    var averageScore: Double

    static let keys: [String] = [
        "averagePutts",
        "greensInRegulation",
        "fairwayHitPercentage",
        "greenMissLeftPercentage",
        "greenMissRightPercentage",
        "greenMissShortPercentage",
        "greenMissLongPercentage",
        "fairwayMissLeftPercentage",
        "fairwayMissRightPercentage",
        "par3Average",
        "par4Average",
        "par5Average",
        "averageScore"
    ]

    static let keyPaths: [String: KeyPath<RoundStats, Double>] = [
        "averagePutts": \.averagePutts,
        "greensInRegulation": \.greensInRegulation,
        "fairwayHitPercentage": \.fairwayHitPercentage,
        "greenMissLeftPercentage": \.greenMissLeftPercentage,
        "greenMissRightPercentage": \.greenMissRightPercentage,
        "greenMissShortPercentage": \.greenMissShortPercentage,
        "greenMissLongPercentage": \.greenMissLongPercentage,
        "fairwayMissLeftPercentage": \.fairwayMissLeftPercentage,
        "fairwayMissRightPercentage": \.fairwayMissRightPercentage,
        "par3Average": \.par3Average,
        "par4Average": \.par4Average,
        "par5Average": \.par5Average,
        "averageScore": \.averageScore
    ]
}

struct ScorecardView: View {
    let holeData: [Hole]
    let courseName: String
    let eloChange: Double
    let currentElo: Double
    let onSave: () -> Void

    @State private var saveButtonDisabled = false
    @Environment(\.dismiss) private var dismiss

    var totalStrokes: Int {
        holeData.reduce(0) { $0 + $1.score }
    }

    var totalPar: Int {
        holeData.reduce(0) { $0 + $1.par }
    }

    var toPar: Int {
        totalStrokes - totalPar
    }

    var totalPutts: Int {
        holeData.reduce(0) { $0 + $1.putts }
    }

    var fairwaysHit: Int {
        holeData.filter { $0.missDirection == .center }.count
    }

    var greensHit: Int {
        holeData.filter { $0.missedGreen == .hitGreen }.count
    }

    var greenMisses: (left: Int, right: Int, short: Int, long: Int) {
        (
            holeData.filter { $0.missedGreen == .left }.count,
            holeData.filter { $0.missedGreen == .right }.count,
            holeData.filter { $0.missedGreen == .short }.count,
            holeData.filter { $0.missedGreen == .long }.count
        )
    }

    var fairwayMisses: (left: Int, right: Int) {
        (
            holeData.filter { $0.missDirection == .left }.count,
            holeData.filter { $0.missDirection == .right }.count
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Scorecard")
                    .font(.largeTitle)
                    .bold()

                Text("Course: \(courseName)")
                    .font(.title2)

                Text("Par: \(totalPar)")
                    .font(.headline)

                VStack(alignment: .leading) {
                    Text("Front 9")
                        .font(.headline)
                    HStack(spacing: 4) {
                        ForEach(0..<9, id: \.self) { index in
                            let hole = holeData[index]
                            let diff = hole.score - hole.par
                            let color: Color = diff == -1 ? .red : (diff == 1 ? .blue : .gray)

                            VStack(spacing: 4) {
                                Text("H\(index + 1)")
                                    .font(.caption2)
                                Text("\(hole.score)")
                                    .font(.caption)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(color))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Back 9")
                        .font(.headline)
                    HStack(spacing: 4) {
                        ForEach(9..<18, id: \.self) { index in
                            let hole = holeData[index]
                            let diff = hole.score - hole.par
                            let color: Color = diff == -1 ? .red : (diff == 1 ? .blue : .gray)

                            VStack(spacing: 4) {
                                Text("H\(index + 1)")
                                    .font(.caption2)
                                Text("\(hole.score)")
                                    .font(.caption)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(color))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text("Total Strokes: \(totalStrokes)")
                        .font(.title3)
                    Text("Score to Par: \(toPar > 0 ? "+\(toPar)" : "\(toPar)")")
                        .font(.title3)
                        .foregroundColor(toPar > 0 ? .red : (toPar < 0 ? .green : .primary))
                    Text("Total Putts: \(totalPutts)")
                    Text("Fairways Hit: \(fairwaysHit)")
                    Text("Greens Hit: \(greensHit)")

                    VStack(spacing: 4) {
                        Text("Green Misses:")
                        Text("Left: \(greenMisses.left), Right: \(greenMisses.right)")
                        Text("Short: \(greenMisses.short), Long: \(greenMisses.long)")
                    }

                    VStack(spacing: 4) {
                        Text("Fairway Misses:")
                        Text("Left: \(fairwayMisses.left), Right: \(fairwayMisses.right)")
                    }
                    
                    VStack(spacing: 6) {
                        Text("ELO Change:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Text("\(eloChange > 0 ? "+" : "")\(String(format: "%.1f", eloChange))")
                            .font(.title2)
                            .foregroundColor(eloChange >= 0 ? .green : .red)
                            .fontWeight(.bold)
                        
                        Text("New ELO: \(String(format: "%.1f", currentElo + eloChange))")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .padding(.top, 10)
                .font(.subheadline)

                Button("Save Stats") {
                    if !saveButtonDisabled {
                        saveButtonDisabled = true
                        onSave()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
                }
                .disabled(saveButtonDisabled)
                .padding()
                .background(saveButtonDisabled ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
}


struct CourseSetupView: View {
    @Binding var courseName: String
    @Binding var slopeRating: String
    var startRound: () -> Void
    
    var isFormValid: Bool {
        !courseName.isEmpty && !slopeRating.isEmpty
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Course Setup")
                .font(.largeTitle)

            TextField("Enter Course Name", text: $courseName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Enter Slope Rating", text: $slopeRating)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Start Round") {
                startRound()
            }
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isFormValid)
        }
        .padding(12)
    }
}

struct HoleEntryView: View {
    @Binding var hole: Hole
    var holeNumber: Int
    var totalScore: Int
    var nextHole: () -> Void
    var previousHole: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Hole \(holeNumber)")
                .font(.largeTitle)

            Text("Total Score: \(totalScore > 0 ? "+\(totalScore)" : "\(totalScore)")")
                .font(.title2)
                .foregroundColor(totalScore > 0 ? .red : (totalScore < 0 ? .green : .black))

            HStack(spacing: 20) {
                ScoreInput(label: "Par", value: $hole.par)
                ScoreInput(label: "Strokes", value: $hole.score)
                ScoreInput(label: "Putts", value: $hole.putts)
            }

            Text("Fairway Hit?")
                .font(.headline)

            HStack(spacing: 8) {
                MissButton(label: "Left", isSelected: hole.missDirection == .left, isSquare: false) {
                    hole.missDirection = .left
                }
                MissButton(label: "Fairway", isSelected: hole.missDirection == .center, isSquare: false) {
                    hole.missDirection = .center
                }
                MissButton(label: "Right", isSelected: hole.missDirection == .right, isSquare: false) {
                    hole.missDirection = .right
                }
            }

            Text("Missed Green Direction?")
                .font(.headline)

            VStack(spacing: 4) {
                HStack {
                    MissButton(label: "Long", isSelected: hole.missedGreen == .long) {
                        hole.missedGreen = .long
                    }
                }

                HStack(spacing: 8) {
                    MissButton(label: "Left", isSelected: hole.missedGreen == .left) {
                        hole.missedGreen = .left
                    }
                    MissButton(label: "Hit", isSelected: hole.missedGreen == .hitGreen) {
                        hole.missedGreen = .hitGreen
                    }
                    MissButton(label: "Right", isSelected: hole.missedGreen == .right) {
                        hole.missedGreen = .right
                    }
                }

                HStack {
                    MissButton(label: "Short", isSelected: hole.missedGreen == .short) {
                        hole.missedGreen = .short
                    }
                }
            }
            .scaleEffect(1.1)

            Spacer()

            HStack(spacing: 20) {
                Button("Back") { previousHole() }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Button("Next") { nextHole() }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(10)
    }
}

struct Hole {
    var par: Int = 4
    var score: Int = 4
    var putts: Int = 2
    var missDirection: MissDirection = .center
    var missedGreen: MissedGreen = .hitGreen
}

enum MissDirection {
    case left, center, right
}

enum MissedGreen {
    case left, short, right, hitGreen, long
}

struct ScoreInput: View {
    var label: String
    @Binding var value: Int

    var body: some View {
        VStack {
            Text(label)
                .font(.headline)
            HStack {
                Button("-") {
                    if value > 1 { value -= 1 }
                }
                .padding(6)

                Text("\(value)")
                    .font(.title)

                Button("+") {
                    value += 1
                }
                .padding(6)
            }
        }
    }
}

struct MissButton: View {
    var label: String
    var isSelected: Bool
    var isSquare: Bool = true
    var action: () -> Void

    var body: some View {
        Button(label) {
            action()
        }
        .padding(6)
        .frame(width: isSquare ? 55 : 100, height: 55)
        .background(isSelected ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(6)
        .font(.body)
    }
}

struct GolfRoundView_Previews: PreviewProvider {
    static var previews: some View {
        GolfRoundView()
    }
}
