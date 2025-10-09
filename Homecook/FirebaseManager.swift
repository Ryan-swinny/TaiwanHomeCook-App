// Homecook/FirebaseManager.swift

import Foundation
import Combine
import FirebaseFirestore // ⭐ 修正：導入 FirebaseFirestore 以識別 ListenerRegistration

class FirebaseManager: ObservableObject {
    
    @Published var cookSpots: [CookSpot] = []
    
    @Published var isLoading = true
    
    // 導入 DatabaseService
    private let dbService = DatabaseService()
    
    // 用於管理 Firestore 監聽的資源
    private var listenerRegistration: ListenerRegistration? // 現在 ListenerRegistration 可以被識別
    
    init() {
        startListeningForCookSpots()
    }
    
    func startListeningForCookSpots() {
        print("【Firebase Manager】開始實時數據監聽...")
        
        listenerRegistration?.remove()
        
        // 呼叫 DatabaseService 的訂閱方法
        listenerRegistration = dbService.subscribeToCookSpots { [weak self] newSpots in
            DispatchQueue.main.async {
                self?.cookSpots = newSpots
                self?.isLoading = false
                print("【DATA SYNC】已接收 \(newSpots.count) 筆 CookSpot 數據。")
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
