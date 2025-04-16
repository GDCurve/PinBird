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
    
    // Changing from counts to percentages
    @State private var fairwayMissDirections: [String: Double] = [:]
    @State private var greenMissDirections: [String: Double] = [:]
    
    @State private var searchQuery = ""
    @State private var filteredUsers: [String] = []
    @State private var followingUsers: [String] = []

    @Binding var selectedTab: String

    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Search Bar
                TextField("Search by First or Last Name", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.top, .horizontal])
                    .onChange(of: searchQuery, perform: { value in
                        filterUsers()
                    })
                
                // Search results
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

                Text("Your Stats")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                // Statistic Squares Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    statBox(title: "Total Rounds", value: "\(totalRounds)")
                    statBox(title: "Avg Putts", value: String(format: "%.1f", avgPutts))
                    statBox(title: "Fairway Hit %", value: String(format: "%.0f", fairwayHitPercentage * 100) + "%")
                    statBox(title: "Green Hit %", value: String(format: "%.0f", greenHitPercentage * 100) + "%")
                }
                .padding(.horizontal)

                // Avg Score box - 2x wide and centered
                HStack {
                    Spacer()
                    statBox(title: "Avg Score", value: String(format: "%.1f", averageScore))
                        .frame(width: UIScreen.main.bounds.width * 0.85)
                    Spacer()
                }
                .padding(.top, 8)

                // Fairway Miss Directions Chart
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

                // Green Miss Directions Chart
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
        })
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

                totalRounds = data?["roundsPlayed"] as? Int ?? 0
                avgPutts = data?["averagePutts"] as? Double ?? 0.0
                fairwayHitPercentage = data?["fairwayHitPercentage"] as? Double ?? 0.0
                greenHitPercentage = data?["greensInRegulation"] as? Double ?? 0.0  // Updated to match database
                averageScore = data?["averageScore"] as? Double ?? 0.0
                
                // Update miss direction stats to use percentages from database
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
        
        // First find the target user
        let fullName = user.split(separator: " ")
        let firstName = String(fullName.first ?? "")
        
        db.collection("users").whereField("name", isEqualTo: firstName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user: \(error.localizedDescription)")
                return
            }

            guard let targetUser = snapshot?.documents.first else { return }
            let targetUserID = targetUser.documentID
            
            // Add currentUserID to target user's followers array
            db.collection("users").document(targetUserID).updateData([
                "followers": FieldValue.arrayUnion([currentUserID])
            ]) { error in
                if let error = error {
                    print("Error following user: \(error.localizedDescription)")
                } else {
                    // Add targetUserID to current user's following array
                    db.collection("users").document(currentUserID).updateData([
                        "following": FieldValue.arrayUnion([targetUserID])
                    ]) { error in
                        if let error = error {
                            print("Error updating following: \(error.localizedDescription)")
                        } else {
                            print("Successfully followed \(user)")
                            // Update local state to reflect the change
                            followingUsers.append(user)
                        }
                    }
                }
            }
        }
    }
    
    private func unfollowUser(for user: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // First find the target user
        let fullName = user.split(separator: " ")
        let firstName = String(fullName.first ?? "")
        
        db.collection("users").whereField("name", isEqualTo: firstName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user: \(error.localizedDescription)")
                return
            }

            guard let targetUser = snapshot?.documents.first else { return }
            let targetUserID = targetUser.documentID
            
            // Remove currentUserID from target user's followers array
            db.collection("users").document(targetUserID).updateData([
                "followers": FieldValue.arrayRemove([currentUserID])
            ]) { error in
                if let error = error {
                    print("Error unfollowing user: \(error.localizedDescription)")
                } else {
                    // Remove targetUserID from current user's following array
                    db.collection("users").document(currentUserID).updateData([
                        "following": FieldValue.arrayRemove([targetUserID])
                    ]) { error in
                        if let error = error {
                            print("Error updating following: \(error.localizedDescription)")
                        } else {
                            print("Successfully unfollowed \(user)")
                            // Update local state to reflect the change
                            if let index = followingUsers.firstIndex(of: user) {
                                followingUsers.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
    }
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
