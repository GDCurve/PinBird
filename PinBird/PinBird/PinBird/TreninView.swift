//
//  TreninView.swift
//  PinBird
//
//  Created by egsango on 24/02/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GameWeakness {
    let area: String
    let score: Double
    let description: String
    let drills: [PracticeDrill]
}

struct PracticeDrill {
    let title: String
    let description: String
    let difficulty: Int
    let estimatedTime: Int
}

struct TreninView: View {
    @Binding var selectedTab: String
    
    @State private var userStats: [String: Double] = [:]
    @State private var weaknesses: [GameWeakness] = []
    @State private var isLoading = true
    @State private var selectedWeakness: GameWeakness?
    @State private var selectedDrill: PracticeDrill?
    @State private var showDrillDetail = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Practice Session")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Spacer()
                    }
                } else if !weaknesses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Area")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        weaknessCard(weakness: weaknesses[0])
                        
                        if weaknesses.count > 1 {
                            Text("Other Areas to Improve")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding([.top, .horizontal])
                            
                            ForEach(1..<min(weaknesses.count, 3), id: \.self) { index in
                                secondaryWeaknessCard(weakness: weaknesses[index])
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Key Stats")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding([.top, .horizontal])
                        
                        statsOverview()
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Not Enough Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Play more rounds to get personalized practice recommendations.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showDrillDetail) {
            if let drill = selectedDrill {
                drillDetailView(drill: drill)
            }
        }
        .onAppear {
            fetchUserStats()
        }
    }
    
    private func weaknessCard(weakness: GameWeakness) -> some View {
        Button {
            selectedWeakness = weakness
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(weakness.area)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: "circle.fill")
                                .foregroundColor(i < Int(round(weakness.score)) ? .white : .white.opacity(0.3))
                                .font(.caption)
                        }
                    }
                }
                
                Text(weakness.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("Recommended Drills")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    ForEach(weakness.drills.indices, id: \.self) { index in
                        let drill = weakness.drills[index]
                        Button {
                            selectedDrill = drill
                            showDrillDetail = true
                        } label: {
                            HStack {
                                Text(drill.title)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(drill.estimatedTime) min")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red, Color.orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func secondaryWeaknessCard(weakness: GameWeakness) -> some View {
        Button {
            selectedWeakness = weakness
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weakness.area)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(weakness.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Image(systemName: "circle.fill")
                            .foregroundColor(i < Int(round(weakness.score)) ? .orange : .gray.opacity(0.3))
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statsOverview() -> some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statItem(title: "GIR", value: String(format: "%.0f%%", (userStats["greensInRegulation"] ?? 0) * 100))
                statItem(title: "Fairways", value: String(format: "%.0f%%", (userStats["fairwayHitPercentage"] ?? 0) * 100))
                statItem(title: "Putts/Round", value: String(format: "%.1f", userStats["averagePutts"] ?? 0))
                statItem(title: "Avg Score", value: String(format: "%.1f", userStats["averageScore"] ?? 0))
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Fairway Miss Tendency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    Spacer()
                    tendencyBar(
                        leftLabel: "Left",
                        rightLabel: "Right",
                        leftValue: userStats["fairwayMissLeftPercentage"] ?? 0,
                        centerValue: userStats["fairwayHitPercentage"] ?? 0,
                        rightValue: userStats["fairwayMissRightPercentage"] ?? 0
                    )
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Green Miss Tendency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    Spacer()
                    greenMissVisualization()
                    Spacer()
                }
            }
        }
    }
    
    private func greenMissVisualization() -> some View {
        let leftMiss = userStats["greenMissLeftPercentage"] ?? 0
        let rightMiss = userStats["greenMissRightPercentage"] ?? 0
        let longMiss = userStats["greenMissLongPercentage"] ?? 0
        let shortMiss = userStats["greenMissShortPercentage"] ?? 0
        let girPercentage = userStats["greensInRegulation"] ?? 0
        
        return ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(String(format: "%.0f%%", longMiss * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                }
                .frame(width: 60)
                .padding(.bottom, 4)
                
                HStack(spacing: 4) {
                    Text(String(format: "%.0f%%", leftMiss * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                    
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 100, height: 100)
                        
                        Text(String(format: "%.0f%%", girPercentage * 100))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text(String(format: "%.0f%%", rightMiss * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(8, corners: [.topRight, .bottomRight])
                }
                
                HStack(spacing: 0) {
                    Text(String(format: "%.0f%%", shortMiss * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                }
                .frame(width: 60)
                .padding(.top, 4)
            }
            
            
        }
        .frame(height: 220)
        .padding(.vertical, 10)
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func tendencyBar(leftLabel: String, rightLabel: String, leftValue: Double, centerValue: Double, rightValue: Double) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(leftLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(rightLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {

                Rectangle()
                    .frame(width: 200, height: 20)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                

                Rectangle()
                    .frame(width: 200 * leftValue, height: 20)
                    .foregroundColor(.red)
                    .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                

                HStack {
                    Spacer().frame(width: 200 * leftValue)
                    Rectangle()
                        .frame(width: 200 * centerValue, height: 20)
                        .foregroundColor(.green)
                }
                

                HStack {
                    Spacer().frame(width: 200 * (leftValue + centerValue))
                    Rectangle()
                        .frame(width: 200 * rightValue, height: 20)
                        .foregroundColor(.blue)
                        .cornerRadius(10, corners: [.topRight, .bottomRight])
                }
                

                HStack {
                    Text(String(format: "%.0f%%", leftValue * 100))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", centerValue * 100))
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", rightValue * 100))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }
            }
        }
        .frame(width: 200)
    }
    
    private func drillDetailView(drill: PracticeDrill) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    Text(drill.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
                
                HStack {
                    Label("Difficulty", systemImage: "star.fill")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        ForEach(0..<3) { i in
                            Image(systemName: "star.fill")
                                .foregroundColor(i < drill.difficulty ? .yellow : .gray.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    Label("Time", systemImage: "clock")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(drill.estimatedTime) minutes")
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                Text("Description")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text(drill.description)
                    .padding(.horizontal)
                
                Spacer()
                
                Button {
                    showDrillDetail = false
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
    
    private func fetchUserStats() {
        isLoading = true
        
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        db.collection("users").document(userID).getDocument { document, error in
            defer {
                isLoading = false
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                
                for key in [
                    "averagePutts", "greensInRegulation", "fairwayHitPercentage",
                    "greenMissLeftPercentage", "greenMissRightPercentage",
                    "greenMissShortPercentage", "greenMissLongPercentage",
                    "fairwayMissLeftPercentage", "fairwayMissRightPercentage",
                    "par3Average", "par4Average", "par5Average",
                    "averageScore", "roundsPlayed"
                ] {
                    if let value = data[key] as? Double {
                        userStats[key] = value
                    }
                }
                
                analyzeWeaknesses()
            }
        }
    }
    
    private func analyzeWeaknesses() {
        var weaknessList: [GameWeakness] = []

        if userStats["roundsPlayed"] ?? 0 >= 1 {
           
            let avgPutts = userStats["averagePutts"] ?? 0
            let puttScore = calculatePuttingScore(avgPutts)
            
            if puttScore > 0 {
                weaknessList.append(GameWeakness(
                    area: "Putting",
                    score: puttScore,
                    description: "You're averaging \(String(format: "%.1f", avgPutts)) putts per round, which is higher than ideal. Focus on distance control and reading greens.",
                    drills: [
                        PracticeDrill(
                            title: "3-6-9 Putting Drill",
                            description: "Place 3 balls at distances of 3, 6, and 9 feet from the hole. Practice making all three in a row. If you miss any, start over. Complete 5 successful rounds.",
                            difficulty: 2,
                            estimatedTime: 20
                        ),
                        PracticeDrill(
                            title: "Clock Drill",
                            description: "Place 12 balls in a circle around the hole at a distance of 3-5 feet, like numbers on a clock. Try to make all 12 putts in a row. Focus on reading subtle breaks from different angles.",
                            difficulty: 3,
                            estimatedTime: 30
                        ),
                        PracticeDrill(
                            title: "Distance Control Ladder",
                            description: "Place markers at 10, 20, 30, and 40 feet from the hole. Hit 5 putts to each distance, focusing on getting each putt within 2 feet of the hole. Track your improvement over time.",
                            difficulty: 2,
                            estimatedTime: 25
                        )
                    ]
                ))
            }
            

            let girPercentage = userStats["greensInRegulation"] ?? 0
            let girScore = calculateGIRScore(girPercentage)
            
            if girScore > 0 {
                weaknessList.append(GameWeakness(
                    area: "Approach Shots",
                    score: girScore,
                    description: "Your GIR percentage is \(String(format: "%.0f%%", girPercentage * 100)). Improving your iron play will help you hit more greens.",
                    drills: [
                        PracticeDrill(
                            title: "9-Ball Distance Control",
                            description: "Pick a target on the range. Hit 9 balls, 3 each at 80%, 90%, and 100% of your normal swing. Focus on consistent contact and distance control.",
                            difficulty: 2,
                            estimatedTime: 25
                        ),
                        PracticeDrill(
                            title: "Numbered Targets",
                            description: "Assign numbers to different targets on the range. Have a friend call out numbers randomly, and hit to the corresponding target. This improves focus and adaptability.",
                            difficulty: 3,
                            estimatedTime: 35
                        ),
                        PracticeDrill(
                            title: "Flag Hunt",
                            description: "Starting with your shortest iron, work your way through your bag hitting one shot to each flag on the range. Focus on landing the ball within a 10-foot radius of each target.",
                            difficulty: 2,
                            estimatedTime: 30
                        )
                    ]
                ))
            }
            

            let fwPercentage = userStats["fairwayHitPercentage"] ?? 0
            let fwScore = calculateFairwayScore(fwPercentage)
            
            if fwScore > 0 {
                weaknessList.append(GameWeakness(
                    area: "Driving Accuracy",
                    score: fwScore,
                    description: "You're finding only \(String(format: "%.0f%%", fwPercentage * 100)) of fairways. More accurate drives will set up easier approach shots.",
                    drills: [
                        PracticeDrill(
                            title: "Corridor Drill",
                            description: "Place two alignment sticks or clubs parallel to each other on the range, creating a corridor slightly wider than your stance. Practice hitting drives between them to develop a straight ball flight.",
                            difficulty: 2,
                            estimatedTime: 20
                        ),
                        PracticeDrill(
                            title: "3-2-1 Control",
                            description: "Hit 3 shots with a 3/4 swing, 2 shots with a normal swing, and 1 shot with maximum effort. Focus on keeping all shots in play and noting the distance differences.",
                            difficulty: 2,
                            estimatedTime: 15
                        ),
                        PracticeDrill(
                            title: "Target Gates",
                            description: "Set up 'gates' (markers) at various distances on the range. Start with wider gates and gradually narrow them as you improve. The goal is to hit through each gate consistently.",
                            difficulty: 3,
                            estimatedTime: 25
                        )
                    ]
                ))
            }
            

            let par3Avg = userStats["par3Average"] ?? 0
            let par4Avg = userStats["par4Average"] ?? 0
            let par5Avg = userStats["par5Average"] ?? 0
            
            let par3Score = calculateParScore(par3Avg - 3.0)
            let par4Score = calculateParScore(par4Avg - 4.0)
            let par5Score = calculateParScore(par5Avg - 5.0)
            
            let maxParScore = max(par3Score, max(par4Score, par5Score))
            
            if maxParScore > 0 {
                if par3Score >= par4Score && par3Score >= par5Score {
                    weaknessList.append(GameWeakness(
                        area: "Par 3 Performance",
                        score: par3Score,
                        description: "You're averaging \(String(format: "%.1f", par3Avg)) on par 3s, which is \(String(format: "%.1f", par3Avg - 3.0)) over par. Focus on tee shot accuracy.",
                        drills: [
                            PracticeDrill(
                                title: "Par 3 Simulation",
                                description: "Choose 5 different targets on the range representing different par 3 distances. For each target, go through your full pre-shot routine and hit one shot. Score each shot as you would on the course.",
                                difficulty: 2,
                                estimatedTime: 20
                            ),
                            PracticeDrill(
                                title: "9-Shot Shape Challenge",
                                description: "Hit 3 shots with each of your common par 3 clubs - straight, fade, and draw. This builds versatility for different par 3 hole shapes.",
                                difficulty: 3,
                                estimatedTime: 25
                            ),
                            PracticeDrill(
                                title: "Pressure Par 3s",
                                description: "At the range, simulate 9 par 3s of different lengths. Give yourself only one ball for each hole and keep score. The limited attempts create pressure similar to on-course situations.",
                                difficulty: 2,
                                estimatedTime: 30
                            )
                        ]
                    ))
                } else if par4Score >= par3Score && par4Score >= par5Score {
                    weaknessList.append(GameWeakness(
                        area: "Par 4 Strategy",
                        score: par4Score,
                        description: "You're averaging \(String(format: "%.1f", par4Avg)) on par 4s, which is \(String(format: "%.1f", par4Avg - 4.0)) over par. Work on drive positioning and approach shots.",
                        drills: [
                            PracticeDrill(
                                title: "Fairway First Strategy",
                                description: "Practice hitting your most accurate club off the tee (not necessarily driver) to a specific target. Then hit an approach shot with the appropriate club for the remaining distance.",
                                difficulty: 2,
                                estimatedTime: 25
                            ),
                            PracticeDrill(
                                title: "Par 4 Sequence Drill",
                                description: "Simulate playing 5 different par 4s by hitting a drive, then an approach shot for each. Score yourself based on drive accuracy and approach proximity to target.",
                                difficulty: 2,
                                estimatedTime: 30
                            ),
                            PracticeDrill(
                                title: "Trouble Recovery",
                                description: "Practice hitting recovery shots from common trouble spots you find on par 4s - from rough, behind trees, or from divots. Focus on getting back in position rather than heroic shots.",
                                difficulty: 3,
                                estimatedTime: 20
                            )
                        ]
                    ))
                } else {
                    weaknessList.append(GameWeakness(
                        area: "Par 5 Strategy",
                        score: par5Score,
                        description: "You're averaging \(String(format: "%.1f", par5Avg)) on par 5s, which is \(String(format: "%.1f", par5Avg - 5.0)) over par. Improve your layup positioning and third shots.",
                        drills: [
                            PracticeDrill(
                                title: "Strategic Layup Practice",
                                description: "Pick a target 80-100 yards from a practice green. Hit 10 shots to this target area with your favorite layup club, focusing on placing the ball in the ideal position for your next shot.",
                                difficulty: 2,
                                estimatedTime: 20
                            ),
                            PracticeDrill(
                                title: "Par 5 Wedge Control",
                                description: "After a good drive and layup, par 5 success often comes down to wedge play. Practice 10 shots each from 40, 60, and 80 yards to build confidence with these scoring distances.",
                                difficulty: 2,
                                estimatedTime: 25
                            ),
                            PracticeDrill(
                                title: "Risk-Reward Decision Making",
                                description: "Simulate going for the green in two on a par 5. Set up a hazard area short of your target and practice deciding when to go for it vs. when to lay up based on your lie and confidence level.",
                                difficulty: 3,
                                estimatedTime: 30
                            )
                        ]
                    ))
                }
            }
            

            weaknessList.sort { $0.score > $1.score }
            

            if weaknessList.isEmpty && !userStats.isEmpty {
                weaknessList.append(GameWeakness(
                    area: "Overall Game Improvement",
                    score: 1.0,
                    description: "Work on all aspects of your game to continue improving your scoring average of \(String(format: "%.1f", userStats["averageScore"] ?? 0)).",
                    drills: [
                        PracticeDrill(
                            title: "9-Shot Drill",
                            description: "Hit 9 different shots with each club - low, medium, and high trajectories with straight, fade, and draw shapes. This builds versatility throughout your bag.",
                            difficulty: 3,
                            estimatedTime: 45
                        ),
                        PracticeDrill(
                            title: "Par 18 Challenge",
                            description: "Hit 18 different shots on the range, simulating a full round. Score each shot as you would on the course, with the goal of shooting par or better.",
                            difficulty: 2,
                            estimatedTime: 30
                        ),
                        PracticeDrill(
                            title: "Skills Test",
                            
                            description: "Conduct a comprehensive skills test: 10 drives for accuracy, 10 approach shots to targets, 10 chips to within 3 feet, and 10 putts from 6 feet. Record your score out of 40 and track improvement over time.",
                            difficulty: 3,
                            estimatedTime: 40
                        )
                    ]
                ))
            }
        }
        
        self.weaknesses = weaknessList
    }
    
    private func calculatePuttingScore(_ putts: Double) -> Double {
        if putts >= 36 {
            return 3.0
        } else if putts >= 33 {
            return 2.0
        } else if putts >= 31 {
            return 1.0
        } else {
            return 0.0
        }
    }
    
    private func calculateGIRScore(_ percentage: Double) -> Double {
        if percentage <= 0.35 {
            return 3.0
        } else if percentage <= 0.5 {
            return 2.0
        } else if percentage <= 0.6 {
            return 1.0
        } else {
            return 0.0
        }
    }
    
    private func calculateFairwayScore(_ percentage: Double) -> Double {
        if percentage <= 0.35 {
            return 3.0
        } else if percentage <= 0.45 {
            return 2.0
        } else if percentage <= 0.55 {
            return 1.0
        } else {
            return 0.0
        }
    }
    
    private func calculateParScore(_ overPar: Double) -> Double {
        if overPar >= 1.5 {
            return 3.0
        } else if overPar >= 0.9 {
            return 2.0
        } else if overPar >= 0.5 {
            return 1.0
        } else {
            return 0.0
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
