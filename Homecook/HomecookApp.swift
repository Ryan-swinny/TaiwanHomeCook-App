//
//  HomecookApp.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import SwiftUI
import FirebaseCore // 確保 Firebase Core 導入

// MARK: - 1. AppDelegate 處理 Firebase 初始化
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // 確保 Firebase 在 App 啟動時配置
    FirebaseApp.configure()
    return true
  }
}

// MARK: - 2. App 結構與環境注入
@main
struct HomecookApp: App {
    
    // 應用程式委託，用於處理 Firebase 設定
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ⭐ 修正點：所有 managers 必須在這裡獨立實例化，並使用小寫駝峰命名法
    // 確保這些 managers 自身的 init() 內部沒有嘗試創建其他 managers 的實例
    @StateObject var authService = AuthService()
    @StateObject var orderManager = OrderManager()
    @StateObject var locationManager = LocationManager() // 必須包含定位管理器
    @StateObject var cookSpotManager = CookSpotManager() // 變數名稱使用小寫駝峰
    
    // 注意：SwiftUI App 結構體必須在 body 之前完成所有 @StateObject 屬性的初始化。
    
    var body: some Scene {
        WindowGroup {
            Group {
                // 根據認證狀態切換根視圖
                if authService.user != nil {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            // 統一將所有服務注入環境
            .environmentObject(authService)
            .environmentObject(orderManager)
            .environmentObject(locationManager)
            .environmentObject(cookSpotManager)
        }
    }
}
