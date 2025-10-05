// HomecookApp.swift

import SwiftUI
import FirebaseCore // 1. 🐞 確保這裡有導入 FirebaseCore

// 定義一個 AppDelegate，負責在 App 啟動時呼叫 FirebaseApp.configure()
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // 2. 🐞 關鍵：在 App 啟動完成時執行初始化
    FirebaseApp.configure()
    return true
  }
}

@main
struct HomecookApp: App {
    
    // 3. 🐞 引入 AppDelegate 讓 SwiftUI App 執行應用程式生命週期方法
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // 創建 OrderManager 的實例，並將它持有在 App 的生命週期中
    @StateObject var orderManager = OrderManager()
    
    // ⭐ 新增：創建 AuthService 的實例
    @StateObject var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            // ⭐ 修正點：根據 authService.user 的狀態來決定顯示哪個 View
            Group {
                // 如果 authService.user 不為 nil，表示已登入，顯示主要內容
                if authService.user != nil {
                    ContentView()
                } else {
                    // 如果 authService.user 為 nil，表示未登入，顯示登錄頁
                    LoginView()
                }
            }
            .environmentObject(orderManager)
            .environmentObject(authService)
        }
    }
}
