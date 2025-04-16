//
//  ContentView.swift
//  PinBird
//
//  Created by egsango on 24/02/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GalvenaisView: View {
    @State var selectedTab = "home"

    var body: some View {
        NavigationView {
            VStack {
                if selectedTab == "home" {
                    ContentView(selectedTab: $selectedTab)
                } else if selectedTab == "practice" {
                    TreninView(selectedTab: $selectedTab)
                } else if selectedTab == "account" {
                    AccountEditView(selectedTab: $selectedTab)
                } else {
                    Text("Unknown tab")
                }
                
                FooterView(selectedTab: $selectedTab)
            }
        }
    }
}


struct ContentView: View {
    @State private var firstName = ""
    @State private var totalRounds = 0
    @State private var avgPutts = 0.0
    @State private var fairwayHitPercentage = 0.0
    @State private var greenHitPercentage = 0.0
    @State private var averageScore = 0.0
    
    @State private var fairwayMissDirections: [String: Double] = [:]
    @State private var greenMissDirections: [String: Double] = [:]
    
    @State private var searchQuery = ""
    @State private var filteredUsers: [String] = []
    @State private var followingUsers: [String] = []
    
    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var userRank: Int = 0
    @State private var userElo: Double = 0.0
    @State private var userLastName: String = ""

    @Binding var selectedTab: String

    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Search by First or Last Name", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.top, .horizontal])
                    .onChange(of: searchQuery, perform: { value in
                        filterUsers()
                    })
                
                if !filteredUsers.isEmpty {
                    VStack {
                        Text("Search Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(filteredUsers, id: \.self) { user in
                            HStack {
                                Text(user)
                                    .padding([.top, .horizontal])

                                Spacer()

                                Button(action: {
                                    if isFollowing(user) {
                                        unfollowUser(for: user)
                                    } else {
                                        followUser(for: user)
                                    }
                                }) {
                                    Text(isFollowing(user) ? "Unfollow" : "Follow")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(isFollowing(user) ? Color.red : Color.blue)
                                        .cornerRadius(8)
                                }
                                .padding(.trailing, 16)
                            }
                        }
                    }
                }

                Text("Hello \(firstName)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                
                VStack(alignment: .leading) {
                    Text("Leaderboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        HStack {
                            Text("Rank")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            
                            Text("Player")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("ELO")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        
                        ForEach(leaderboardData.prefix(7), id: \.id) { entry in
                            leaderboardRow(rank: entry.rank, name: entry.name, lastName: entry.lastName, elo: entry.elo)
                        }
                        
                        if userRank > 7 {
                            Divider()
                                .padding(.horizontal)
                            
                            leaderboardRow(rank: userRank, name: firstName, lastName: userLastName, elo: userElo)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                Text("Your Stats")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    statBox(title: "Total Rounds", value: "\(totalRounds)")
                    statBox(title: "Avg Putts", value: String(format: "%.1f", avgPutts))
                    statBox(title: "Fairway Hit %", value: String(format: "%.0f", fairwayHitPercentage * 100) + "%")
                    statBox(title: "Green Hit %", value: String(format: "%.0f", greenHitPercentage * 100) + "%")
                }
                .padding(.horizontal)

                HStack {
                    Spacer()
                    statBox(title: "Avg Score", value: String(format: "%.1f", averageScore))
                        .frame(width: UIScreen.main.bounds.width * 0.85)
                    Spacer()
                }
                .padding(.top, 8)

                VStack(alignment: .leading) {
                    Text("Fairway Miss Directions")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding([.top, .leading, .trailing])

                    fairwayMissChart(missDirections: fairwayMissDirections)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading) {
                    Text("Green Miss Directions")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding([.top, .leading])

                    directionalMissChart(missDirections: greenMissDirections)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        .onAppear(perform: {
            fetchUserStats()
            fetchFollowingUsers()
            fetchLeaderboardData()
        })
    }

    private func leaderboardRow(rank: Int, name: String, lastName: String, elo: Double) -> some View {
        HStack {
            Text("\(rank).")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .foregroundColor(
                    rank == 1 ? .yellow :
                    rank == 2 ? Color.gray :
                    rank == 3 ? Color(red: 0.8, green: 0.5, blue: 0.2) : .primary
                )
                .frame(width: 50, alignment: .leading)
            
            Text("\(name) \(lastName.isEmpty ? "" : String(lastName.first!)).")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
            
            Spacer()
            
            Text("\(Int(elo))")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal)
    }

    private func statBox(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(12)
    }

    private func directionalMissChart(missDirections: [String: Double]) -> some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                missDirectionBox(direction: "Long", percentage: missDirections["greenMissLongPercentage"] ?? 0.0)
                Spacer()
            }

            HStack {
                missDirectionBox(direction: "Left", percentage: missDirections["greenMissLeftPercentage"] ?? 0.0)
                Spacer()
                missDirectionBox(direction: "Hit", percentage: greenHitPercentage)
                Spacer()
                missDirectionBox(direction: "Right", percentage: missDirections["greenMissRightPercentage"] ?? 0.0)
            }

            HStack {
                Spacer()
                missDirectionBox(direction: "Short", percentage: missDirections["greenMissShortPercentage"] ?? 0.0)
                Spacer()
            }
        }
    }

    private func fairwayMissChart(missDirections: [String: Double]) -> some View {
        HStack {
            Spacer()
            missDirectionBox(direction: "Left", percentage: missDirections["fairwayMissLeftPercentage"] ?? 0.0)
            Spacer()
            missDirectionBox(direction: "Hit", percentage: fairwayHitPercentage)
            Spacer()
            missDirectionBox(direction: "Right", percentage: missDirections["fairwayMissRightPercentage"] ?? 0.0)
            Spacer()
        }
    }

    private func missDirectionBox(direction: String, percentage: Double) -> some View {
        VStack {
            Text(direction)
                .font(.caption)
                .foregroundColor(.gray)
            Text(String(format: "%.0f%%", percentage * 100))
                .font(.headline)
                .frame(width: 50, height: 50)
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
        }
    }

    private func fetchUserStats() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                firstName = data?["name"] as? String ?? ""
                userLastName = data?["surname"] as? String ?? ""
                userElo = data?["elo"] as? Double ?? 0.0

                totalRounds = data?["roundsPlayed"] as? Int ?? 0
                avgPutts = data?["averagePutts"] as? Double ?? 0.0
                fairwayHitPercentage = data?["fairwayHitPercentage"] as? Double ?? 0.0
                greenHitPercentage = data?["greensInRegulation"] as? Double ?? 0.0
                averageScore = data?["averageScore"] as? Double ?? 0.0
                
                fairwayMissDirections = [
                    "fairwayMissLeftPercentage": data?["fairwayMissLeftPercentage"] as? Double ?? 0.0,
                    "fairwayMissRightPercentage": data?["fairwayMissRightPercentage"] as? Double ?? 0.0
                ]
                
                greenMissDirections = [
                    "greenMissLeftPercentage": data?["greenMissLeftPercentage"] as? Double ?? 0.0,
                    "greenMissRightPercentage": data?["greenMissRightPercentage"] as? Double ?? 0.0,
                    "greenMissShortPercentage": data?["greenMissShortPercentage"] as? Double ?? 0.0,
                    "greenMissLongPercentage": data?["greenMissLongPercentage"] as? Double ?? 0.0
                ]
            }
        }
    }
    
    private func fetchFollowingUsers() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let followingIDs = data?["following"] as? [String] ?? []
                
                var followingNames: [String] = []
                let group = DispatchGroup()
                
                for id in followingIDs {
                    group.enter()
                    db.collection("users").document(id).getDocument { doc, err in
                        if let doc = doc, doc.exists {
                            let userData = doc.data()
                            let firstName = userData?["name"] as? String ?? ""
                            let lastName = userData?["surname"] as? String ?? ""
                            followingNames.append("\(firstName) \(lastName)")
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.followingUsers = followingNames
                }
            }
        }
    }
    
    private func fetchLeaderboardData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let followingIDs = data?["following"] as? [String] ?? []
                var allIDs = followingIDs
                allIDs.append(userID)
                
                var entries: [LeaderboardEntry] = []
                let group = DispatchGroup()
                
                for id in allIDs {
                    group.enter()
                    db.collection("users").document(id).getDocument { doc, err in
                        if let doc = doc, doc.exists {
                            let userData = doc.data()
                            let entry = LeaderboardEntry(
                                id: id,
                                rank: 0,
                                name: userData?["name"] as? String ?? "",
                                lastName: userData?["surname"] as? String ?? "",
                                elo: userData?["elo"] as? Double ?? 0.0
                            )
                            entries.append(entry)
                            
                            if id == userID {
                                self.userElo = entry.elo
                            }
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    let sortedEntries = entries.sorted { $0.elo > $1.elo }
                    
                    var rankedEntries: [LeaderboardEntry] = []
                    for (index, var entry) in sortedEntries.enumerated() {
                        entry.rank = index + 1
                        rankedEntries.append(entry)
                        
                        if entry.id == userID {
                            self.userRank = entry.rank
                        }
                    }
                    
                    self.leaderboardData = rankedEntries
                }
            }
        }
    }

    private func filterUsers() {
        guard !searchQuery.isEmpty else {
            filteredUsers = []
            return
        }
        
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            filteredUsers = snapshot?.documents.compactMap { document in
                let data = document.data()
                let firstName = data["name"] as? String ?? ""
                let lastName = data["surname"] as? String ?? ""
                if firstName.lowercased().contains(searchQuery.lowercased()) || lastName.lowercased().contains(searchQuery.lowercased()) {
                    return "\(firstName) \(lastName)"
                }
                return nil
            } ?? []
        }
    }
    
    private func isFollowing(_ user: String) -> Bool {
        return followingUsers.contains(user)
    }
    
    private func followUser(for user: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let fullName = user.split(separator: " ")
        let firstName = String(fullName.first ?? "")
        
        db.collection("users").whereField("name", isEqualTo: firstName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user: \(error.localizedDescription)")
                return
            }

            guard let targetUser = snapshot?.documents.first else { return }
            let targetUserID = targetUser.documentID
            
            db.collection("users").document(targetUserID).updateData([
                "followers": FieldValue.arrayUnion([currentUserID])
            ]) { error in
                if let error = error {
                    print("Error following user: \(error.localizedDescription)")
                } else {
                    db.collection("users").document(currentUserID).updateData([
                        "following": FieldValue.arrayUnion([targetUserID])
                    ]) { error in
                        if let error = error {
                            print("Error updating following: \(error.localizedDescription)")
                        } else {
                            print("Successfully followed \(user)")
                            followingUsers.append(user)
                            fetchLeaderboardData()
                        }
                    }
                }
            }
        }
    }
    
    private func unfollowUser(for user: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let fullName = user.split(separator: " ")
        let firstName = String(fullName.first ?? "")
        
        db.collection("users").whereField("name", isEqualTo: firstName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user: \(error.localizedDescription)")
                return
            }

            guard let targetUser = snapshot?.documents.first else { return }
            let targetUserID = targetUser.documentID
            
            db.collection("users").document(targetUserID).updateData([
                "followers": FieldValue.arrayRemove([currentUserID])
            ]) { error in
                if let error = error {
                    print("Error unfollowing user: \(error.localizedDescription)")
                } else {
                    db.collection("users").document(currentUserID).updateData([
                        "following": FieldValue.arrayRemove([targetUserID])
                    ]) { error in
                        if let error = error {
                            print("Error updating following: \(error.localizedDescription)")
                        } else {
                            print("Successfully unfollowed \(user)")
                            if let index = followingUsers.firstIndex(of: user) {
                                followingUsers.remove(at: index)
                            }
                            fetchLeaderboardData()
                        }
                    }
                }
            }
        }
    }
}

struct LeaderboardEntry {
    var id: String
    var rank: Int
    var name: String
    var lastName: String
    var elo: Double
}

struct AccountEditView: View {
    @Binding var selectedTab: String
    @AppStorage("irIelogojies") private var irIelogojies = false
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var handicap = ""
    @State private var homeClub = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            Text("Edit Account")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Handicap", text: $handicap)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Home Club", text: $homeClub)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: logOut) {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .onAppear(perform: fetchUserData)
    }
    
    private func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                firstName = data?["name"] as? String ?? ""
                lastName = data?["surname"] as? String ?? ""
                handicap = data?["handicap"] as? String ?? ""
                homeClub = data?["homeClub"] as? String ?? ""
            }
        }
    }
    
    private func saveChanges() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let updatedData: [String: Any] = [
            "name": firstName,
            "surname": lastName,
            "handicap": handicap,
            "homeClub": homeClub
        ]
        
        db.collection("users").document(userID).updateData(updatedData) { error in
            if let error = error {
                print("Error updating data: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
            }
        }
    }
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
            irIelogojies = false
            selectedTab = "home"
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct FooterView: View {
    @Binding var selectedTab: String

    var body: some View {
        HStack {
            Spacer()
            Button(action: { selectedTab = "home" }) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Home").font(.caption)
                }
                .foregroundColor(selectedTab == "home" ? .blue : .primary)
            }
            Spacer()

            NavigationLink(destination: GolfRoundView()) {
                Text("Play Golf")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 120, height: 50)
                    .background(Color.green)
                    .clipShape(Capsule())
            }

            Spacer()

            Button(action: { selectedTab = "practice" }) {
                VStack {
                    Image(systemName: "figure.golf")
                    Text("Practice").font(.caption)
                }
                .foregroundColor(selectedTab == "practice" ? .blue : .primary)
            }
            Spacer()

            Button(action: { selectedTab = "account" }) {
                VStack {
                    Image(systemName: "person.fill")
                    Text("Account").font(.caption)
                }
                .foregroundColor(selectedTab == "account" ? .blue : .primary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}


#Preview {
    GalvenaisView()
}
