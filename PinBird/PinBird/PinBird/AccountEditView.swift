//
//  AccountEditView.swift
//  PinBird
//
//  Created by egsango on 07/05/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AccountEditView: View {
    @Binding var selectedTab: String
    @AppStorage("irIelogojies") private var irIelogojies = false
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var handicap = ""
    @State private var homeClub = ""
    @Environment(\.presentationMode) var presentationMode
    
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
            
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.rootViewController = UIHostingController(rootView: AccountView())
            window?.makeKeyAndVisible()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
