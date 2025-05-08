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
    @AppStorage("irIelogojies") private var irIelogojies = false
    @Environment(\.colorScheme) private var colorScheme

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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !irIelogojies {
                selectedTab = "account"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = windowScene?.windows.first
                    window?.rootViewController = UIHostingController(rootView: AccountView())
                    window?.makeKeyAndVisible()
                }
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
    @State private var showingSearchResults = false

    @Binding var selectedTab: String
    @Environment(\.colorScheme) private var colorScheme

    private let db = Firestore.firestore()
    
    private var primaryColor: Color { Color(red: 0.12, green: 0.64, blue: 0.27) }
    private var secondaryColor: Color { colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color(red: 0.95, green: 0.95, blue: 0.97) }
    private var accentColor: Color { Color(red: 0.0, green: 0.48, blue: 0.8) }
    private var cardBgColor: Color { colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white }
    private var textColor: Color { colorScheme == .dark ? Color.white : Color.primary }
    private var secondaryTextColor: Color { colorScheme == .dark ? Color(red: 0.8, green: 0.8, blue: 0.85) : Color.secondary }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Search golfers", text: $searchQuery)
                            .font(.system(size: 16))
                            .padding(10)
                            .onChange(of: searchQuery, perform: { value in
                                filterUsers()
                                showingSearchResults = !searchQuery.isEmpty
                            })
                        
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                showingSearchResults = false
                                filteredUsers = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .background(secondaryColor)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                

                if showingSearchResults && !filteredUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Results")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .foregroundColor(textColor)

                        ForEach(filteredUsers, id: \.self) { user in
                            HStack {
                                Text(user)
                                    .font(.system(size: 16))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .foregroundColor(textColor)

                                Spacer()

                                Button(action: {
                                    if isFollowing(user) {
                                        unfollowUser(for: user)
                                    } else {
                                        followUser(for: user)
                                    }
                                }) {
                                    Text(isFollowing(user) ? "Unfollow" : "Follow")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isFollowing(user) ? Color.red.opacity(0.8) : accentColor)
                                        .cornerRadius(12)
                                }
                                .padding(.trailing)
                            }
                            .background(cardBgColor)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                            
                            if user != filteredUsers.last {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(cardBgColor)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }


                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title3)
                        .foregroundColor(secondaryTextColor)
                    
                    Text(firstName)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(primaryColor)
                }
                .padding(.horizontal)
                .padding(.top, showingSearchResults ? 0 : 8)
                

                VStack(alignment: .leading, spacing: 12) {
                    Text("Leaderboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .foregroundColor(textColor)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Rank")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
                                .frame(width: 50, alignment: .leading)
                            
                            Text("Player")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
                            
                            Spacer()
                            
                            Text("ELO")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
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
                    .padding(.vertical, 12)
                    .background(cardBgColor)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }


                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Stats")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .foregroundColor(textColor)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statBox(title: "Total Rounds", value: "\(totalRounds)", icon: "flag.fill")
                        statBox(title: "Avg Putts", value: String(format: "%.1f", avgPutts), icon: "circle.grid.cross.fill")
                        statBox(title: "Fairway Hit %", value: String(format: "%.0f", fairwayHitPercentage * 100) + "%", icon: "arrow.up.and.down.and.arrow.left.and.right")
                        statBox(title: "Green Hit %", value: String(format: "%.0f", greenHitPercentage * 100) + "%", icon: "leaf.fill")
                    }
                    .padding(.horizontal)

                    HStack {
                        Spacer()
                        statBox(title: "Average Score", value: String(format: "%.1f", averageScore), icon: "rosette", isLarge: true)
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)


                VStack(alignment: .leading, spacing: 16) {

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(primaryColor)
                            
                            Text("Fairway Miss Directions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(textColor)
                        }
                        .padding(.horizontal)

                        fairwayMissChart(missDirections: fairwayMissDirections)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                            .background(cardBgColor)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                    
                 
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(primaryColor)
                            
                            Text("Green Miss Directions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(textColor)
                        }
                        .padding(.horizontal)

                        directionalMissChart(missDirections: greenMissDirections)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                            .background(cardBgColor)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color(red: 0.97, green: 0.97, blue: 0.98))
        .onAppear(perform: {
            fetchUserStats()
            fetchFollowingUsers()
            fetchLeaderboardData()
        })
    }

    private func leaderboardRow(rank: Int, name: String, lastName: String, elo: Double) -> some View {
        HStack {
            Text("\(rank)")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    rank == 1 ? Color.yellow :
                    rank == 2 ? Color.gray :
                    rank == 3 ? Color(red: 0.8, green: 0.5, blue: 0.2) : accentColor.opacity(0.7)
                )
                .clipShape(Circle())
                .padding(.trailing, 4)
            
            Text("\(name) \(lastName.isEmpty ? "" : String(lastName.first!)).")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .foregroundColor(textColor)
            
            Spacer()
            
            Text("\(Int(elo))")
                .font(rank <= 3 ? .headline : .body)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(rank == userRank ? secondaryColor : Color.clear)
        .cornerRadius(8)
    }

    private func statBox(title: String, value: String, icon: String, isLarge: Bool = false) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 22 : 18))
                    .foregroundColor(primaryColor)
                
                Spacer()
            }
            
            HStack {
                Spacer()
                Text(value)
                    .font(isLarge ? .system(size: 36, weight: .bold) : .system(size: 28, weight: .bold))
                    .foregroundColor(accentColor)
                Spacer()
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: isLarge ? 120 : 100)
        .background(cardBgColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
    }

    private func directionalMissChart(missDirections: [String: Double]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                missDirectionBox(direction: "Long", percentage: missDirections["greenMissLongPercentage"] ?? 0.0)
                Spacer()
            }

            HStack {
                missDirectionBox(direction: "Left", percentage: missDirections["greenMissLeftPercentage"] ?? 0.0)
                Spacer()
                missDirectionBox(direction: "Hit", percentage: greenHitPercentage, isHit: true)
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
            missDirectionBox(direction: "Hit", percentage: fairwayHitPercentage, isHit: true)
            Spacer()
            missDirectionBox(direction: "Right", percentage: missDirections["fairwayMissRightPercentage"] ?? 0.0)
            Spacer()
        }
    }

    private func missDirectionBox(direction: String, percentage: Double, isHit: Bool = false) -> some View {
        VStack {
            Text(direction)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryTextColor)
            
            Text(String(format: "%.0f%%", percentage * 100))
                .font(.headline)
                .foregroundColor(isHit ? primaryColor : textColor)
                .frame(width: 60, height: 60)
                .background(
                    isHit ? primaryColor.opacity(colorScheme == .dark ? 0.4 : 0.3) : secondaryColor
                )
                .cornerRadius(isHit ? 30 : 10)
                .overlay(
                    RoundedRectangle(cornerRadius: isHit ? 30 : 10)
                        .stroke(isHit ? primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
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
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            filteredUsers = snapshot?.documents.compactMap { document in
                let documentID = document.documentID
                if documentID == currentUserID {
                    return nil
                }
                
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

struct FooterView: View {
    @Binding var selectedTab: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Spacer()
            Button(action: { selectedTab = "home" }) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Home").font(.caption)
                }
                .foregroundColor(selectedTab == "home" ? .blue : (colorScheme == .dark ? .white : .primary))
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
                .foregroundColor(selectedTab == "practice" ? .blue : (colorScheme == .dark ? .white : .primary))
            }
            Spacer()

            Button(action: { selectedTab = "account" }) {
                VStack {
                    Image(systemName: "person.fill")
                    Text("Account").font(.caption)
                }
                .foregroundColor(selectedTab == "account" ? .blue : (colorScheme == .dark ? .white : .primary))
            }
            Spacer()
        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(.systemGray6))
    }
}


#Preview {
    GalvenaisView()
}
