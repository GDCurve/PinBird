//
//  TreninView.swift
//  PinBird
//
//  Created by egsango on 24/02/2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct TreninView: View {
    @Binding var selectedTab: String

    var body: some View {
        VStack {
            Text("Practice Page")
                .font(.title)
                .padding()

            Spacer()
        }
    }
}



//struct NotificationsTab: View {
//    @State private var friendRequests: [UserProfile] = []
//    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
//
//    var body: some View {
//        NavigationView {
//            VStack(alignment: .leading, spacing: 16) {
//                Text("Friend Requests")
//                    .font(.title)
//                    .bold()
//                    .padding(.horizontal)
//
//                if friendRequests.isEmpty {
//                    Text("No friend requests.")
//                        .padding(.horizontal)
//                        .foregroundColor(.gray)
//                } else {
//                    List {
//                        ForEach(friendRequests) { user in
//                            VStack(alignment: .leading) {
//                                Text("\(user.name) \(user.surname)")
//                                    .font(.headline)
//
//                                HStack {
//                                    Button(action: {
//                                        acceptFriendRequest(from: user)
//                                    }) {
//                                        Text("Accept")
//                                            .frame(maxWidth: .infinity)
//                                            .padding()
//                                            .background(Color.green)
//                                            .foregroundColor(.white)
//                                            .cornerRadius(12)
//                                    }
//
//                                    Button(action: {
//                                        declineFriendRequest(from: user)
//                                    }) {
//                                        Text("Decline")
//                                            .frame(maxWidth: .infinity)
//                                            .padding()
//                                            .background(Color.red)
//                                            .foregroundColor(.white)
//                                            .cornerRadius(12)
//                                    }
//                                }
//                            }
//                            .padding(.vertical)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Notifications")
//            .onAppear {
//                fetchFriendRequests()
//            }
//        }
//    }
//
//    func fetchFriendRequests() {
//        let db = Firestore.firestore()
//        db.collection("users")
//            .document(currentUserId)
//            .collection("friendRequests")
//            .getDocuments { snapshot, error in
//                guard let docs = snapshot?.documents else { return }
//                var requests: [UserProfile] = []
//
//                let group = DispatchGroup()
//
//                for doc in docs {
//                    let senderId = doc.documentID
//                    group.enter()
//                    db.collection("users").document(senderId).getDocument { userSnap, _ in
//                        if let userData = userSnap?.data() {
//                            // Fetch only the name and surname for incoming friend requests
//                            if let name = userData["name"] as? String,
//                               let surname = userData["surname"] as? String {
//                                let userProfile = UserProfile(
//                                    id: senderId,
//                                    name: name,
//                                    surname: surname,
//                                    handicap: 0.0, // No need to fetch these fields for the notifications
//                                    homeClub: "",
//                                    gender: "",
//                                    elo: 0,
//                                    friends: [],
//                                    friendRequests: [],
//                                    roundsPlayed: 0,
//                                    averagePutts: 0.0,
//                                    greensInRegulation: 0.0,
//                                    fairwayHitPercentage: 0.0,
//                                    fairwayMissLeftPercentage: 0.0,
//                                    fairwayMissRightPercentage: 0.0,
//                                    fairwaysHit: 0,
//                                    fairwaysMissedLeft: 0,
//                                    fairwaysMissedRight: 0,
//                                    greenMissLeftPercentage: 0.0,
//                                    greenMissRightPercentage: 0.0,
//                                    greenMissShortPercentage: 0.0,
//                                    greenMissLongPercentage: 0.0,
//                                    par3Average: 0.0,
//                                    par4Average: 0.0,
//                                    par5Average: 0.0,
//                                    averageScore: 0.0
//                                )
//                                requests.append(userProfile)
//                            }
//                        }
//                        group.leave()
//                    }
//                }
//
//                group.notify(queue: .main) {
//                    self.friendRequests = requests
//                }
//            }
//    }
//
//    func acceptFriendRequest(from user: UserProfile) {
//        let db = Firestore.firestore()
//        let userRef = db.collection("users")
//
//        // Add to each other's friend lists
//        userRef.document(currentUserId).collection("friends").document(user.id).setData(["timestamp": FieldValue.serverTimestamp()])
//        userRef.document(user.id).collection("friends").document(currentUserId).setData(["timestamp": FieldValue.serverTimestamp()])
//
//        // Remove the request
//        userRef.document(currentUserId).collection("friendRequests").document(user.id).delete()
//
//        // Update UI
//        self.friendRequests.removeAll { $0.id == user.id }
//    }
//
//    func declineFriendRequest(from user: UserProfile) {
//        let db = Firestore.firestore()
//        db.collection("users").document(currentUserId).collection("friendRequests").document(user.id).delete()
//        self.friendRequests.removeAll { $0.id == user.id }
//    }
//}
//
//struct UserProfile: Identifiable {
//    var id: String
//    var name: String
//    var surname: String
//    var handicap: Double
//    var homeClub: String
//    var gender: String
//    var elo: Int
//    var friends: [String]
//    var friendRequests: [String]
//    var roundsPlayed: Int
//    var averagePutts: Double
//    var greensInRegulation: Double
//    var fairwayHitPercentage: Double
//    var fairwayMissLeftPercentage: Double
//    var fairwayMissRightPercentage: Double
//    var fairwaysHit: Int
//    var fairwaysMissedLeft: Int
//    var fairwaysMissedRight: Int
//    var greenMissLeftPercentage: Double
//    var greenMissRightPercentage: Double
//    var greenMissShortPercentage: Double
//    var greenMissLongPercentage: Double
//    var par3Average: Double
//    var par4Average: Double
//    var par5Average: Double
//    var averageScore: Double
//}
