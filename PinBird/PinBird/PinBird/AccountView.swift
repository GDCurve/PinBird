//
//  AccountView.swift
//  PinBird
//
//  Created by egsango on 24/02/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore

struct AccountView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var selectedTab = "home"
    @AppStorage("irIelogojies") private var irIelogojies = false

    var body: some View {
        NavigationStack {
            if irIelogojies {
                GalvenaisView()
            } else {
                VStack {
                    Text("Log In")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                    TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Log In") {
                        login()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding(.all)
            }
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                irIelogojies = true
                switchToGalvenaisView()
            }
        }
    }

    func switchToGalvenaisView() {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: GalvenaisView())
            window.makeKeyAndVisible()
        }
    }
}

struct SignUpView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var surname = ""
    @State private var handicap = ""
    @State private var homeClub = ""
    @State private var gender = "Male"
    @State private var selectedTab = "home"
    
    @AppStorage("irIelogojies") private var irIelogojies = false

    var body: some View {
        NavigationStack {
            if irIelogojies {
                GalvenaisView()
            } else {
                VStack {
                    Text("Sign Up")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                    TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("First Name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Last Name", text: $surname).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Handicap", text: $handicap).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Home Club", text: $homeClub).textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button("Sign Up") {
                        registerUser()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    NavigationLink(destination: AccountView()) {
                        Text("Already have an account? Log In")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding(.all)
            }
        }
    }
    func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "name": name,
                    "surname": surname,
                    "handicap": handicap,
                    "homeClub": homeClub,
                    "gender": gender,
                    "elo": 300,
                    "followers": [],
                    "following": [],
                    "roundsPlayed": 0,
                    "averagePutts": 0.0,
                    "greensInRegulation": 0.0,
                    "fairwayHitPercentage": 0.0,
                    "fairwayMissLeftPercentage": 0.0,
                    "fairwayMissRightPercentage": 0.0,
                    "fairwaysHit": 0,
                    "fairwaysMissedLeft": 0,
                    "fairwaysMissedRight": 0,
                    "greenMissLeftPercentage": 0.0,
                    "greenMissRightPercentage": 0.0,
                    "greenMissShortPercentage": 0.0,
                    "greenMissLongPercentage": 0.0,
                    "par3Average": 0.0,
                    "par4Average": 0.0,
                    "par5Average": 0.0,
                    "averageScore": 0.0
                ]

                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        irIelogojies = true
                        switchToGalvenaisView()
                    }
                }
            }
        }
    }


    func switchToGalvenaisView() {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: GalvenaisView())
            window.makeKeyAndVisible()
        }
    }
}

#Preview {
    AccountView()
}
