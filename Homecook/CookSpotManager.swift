//
//  CookSpotManager.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import Foundation
import FirebaseFirestore
import Combine // ⭐ 關鍵修正：必須導入 Combine 才能使用 @Published

/// 負責管理和發布實時 CookSpot 數據的 ObservableObject。
class CookSpotManager: ObservableObject {
    
    // 假設 DatabaseService 存在並已修正
    private let dbService = DatabaseService()
    
    // @Published 依賴 Combine
    @Published var cookSpots: [CookSpot] = []
    
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        startListeningForCookSpots()
    }
    
    deinit {
        // 在 Manager 銷毀時，移除監聽器以釋放資源
        listenerRegistration?.remove()
    }
    
    /// 啟動對 CookSpots 集合的實時監聽。
    func startListeningForCookSpots() {
        
        listenerRegistration?.remove()
        
        // 呼叫 DatabaseService 的訂閱方法
        // 假設 dbService.subscribeToCookSpots 存在且返回 ListenerRegistration
        listenerRegistration = dbService.subscribeToCookSpots { [weak self] newSpots in
            // 將最新數據賦值給 @Published 變數，觸發 UI 刷新
            DispatchQueue.main.async {
                self?.cookSpots = newSpots
                print("【DATA SYNC】已接收 \(newSpots.count) 筆 CookSpot 數據。")
            }
        }
    }
}
