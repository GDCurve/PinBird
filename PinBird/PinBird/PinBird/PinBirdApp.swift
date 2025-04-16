import SwiftUI
import FirebaseCore
import FirebaseAuth
import Firebase
import FirebaseInAppMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
        
        return true
    }
}

@main
struct PinBirdApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("irIelogojies") private var irIelogojies = false
    @State private var selectedTab = "home"

    var body: some Scene {
        WindowGroup {
            if irIelogojies {
                GalvenaisView()
            } else {
                NavigationView {
                    AccountView()
                }
            }
        }
    }
}
