import SwiftUI

#if os(iOS)
import Combine
#endif

@main
struct MyApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var liquidConfig = LiquidGlassConfig.shared
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(iOS)
                .preferredColorScheme(
                    liquidConfig.appearanceMode == 1 ? .light : (liquidConfig.appearanceMode == 2 ? .dark : nil)
                )
                #endif
        }
    }
}
