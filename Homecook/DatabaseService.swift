//
//  DatabaseService.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import Foundation
import FirebaseFirestore

// 導入 CookSpot 結構，確保類型可用
// import CookSpot // 假設 CookSpot 已經被正確導入或定義

/// 處理所有與 Firestore 的數據交互
class DatabaseService {
    
    private let db = Firestore.firestore()
    private let cookSpotsCollection = "cookSpots" // 私廚數據集合名稱
    private let ordersCollection = "orders"     // 訂單數據集合名稱
    
    // MARK: - 1. 讀取數據 (實時監聽 CookSpots)
    
    /// 設置一個實時監聽器來持續追蹤 CookSpots 集合中的變動。
    /// - Parameter completion: 每當數據有變動時，就會觸發這個包含最新 CookSpot 列表的回調。
    /// - Returns: Firestore ListenerRegistration，用於在不再需要時移除監聽器。
    func subscribeToCookSpots(completion: @escaping ([CookSpot]) -> Void) -> ListenerRegistration {
        
        // ⭐ 關鍵：使用 addSnapshotListener 進行實時監聽
        return db.collection(cookSpotsCollection)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Error listening to CookSpots: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                // 將 Firestore 文件轉換為我們的 CookSpot 結構
                let spots = snapshot?.documents.compactMap { doc -> CookSpot? in
                    do {
                        // 嘗試解碼為 CookSpot 結構
                        var spot = try doc.data(as: CookSpot.self)
                        // 使用 Firestore 文件 ID 作為 CookSpot 的 ID
                        spot.id = UUID(uuidString: doc.documentID)
                        return spot
                    } catch {
                        print("Error decoding CookSpot: \(error)")
                        return nil
                    }
                } ?? []
                
                // 數據更新，呼叫回調函數
                completion(spots)
            }
    }
    
    // MARK: - 2. 寫入數據 (Submit Order)
    
    // 訂單寫入邏輯保持不變
    func submitOrder(orderData: [String: Any], completion: @escaping (Bool) -> Void) {
        
        var ref: DocumentReference? = nil
        ref = db.collection(ordersCollection).addDocument(data: orderData) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Order successfully written with ID: \(ref!.documentID)")
                completion(true)
            }
        }
    }
}
