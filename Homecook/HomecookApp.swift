//
//  HomecookApp.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
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
    
    // ⭐ 核心修正：確保所有 manager 都被正確且簡潔地初始化
    
    // 認證服務 (AuthService)
    @StateObject var authService = AuthService()
    
    // 訂單管理 (OrderManager)
    @StateObject var orderManager = OrderManager()
    
    // 定位服務 (LocationManager)
    @StateObject var locationManager = LocationManager()
    
    // CookSpot 專用 Manager (如果你決定保留它)
    @StateObject var cookSpotManager = CookSpotManager()
    
    // ⭐ 修正點：FirebaseManager 變數名稱使用小寫駝峰，並移除類型標註
    @StateObject var firebaseManager = FirebaseManager()
    
    
    var body: some Scene {
        WindowGroup {
            Group {
                // ⭐ 測試模式：直接載入主要內容
                ContentView()
                // 統一將所有服務注入環境
                    .environmentObject(authService)
                    .environmentObject(orderManager)
                    .environmentObject(locationManager)
                    .environmentObject(cookSpotManager)
                    .environmentObject(firebaseManager) // FirebaseManager 現已注入
            }
        }
    }
}
