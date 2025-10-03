// HomecookApp.swift (App 的入口點)

import SwiftUI

@main
struct HomecookApp: App {
    
    // 創建 OrderManager 的實例，並將它持有在 App 的生命週期中
    @StateObject var orderManager = OrderManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 將 orderManager 注入為環境物件，讓所有子視圖都能使用
                .environmentObject(orderManager)
        }
    }
}
