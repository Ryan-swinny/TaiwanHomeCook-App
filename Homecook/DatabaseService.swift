import Foundation
import FirebaseFirestore
// 🐞 修正：我們不再導入 FirebaseFirestoreSwift，因為它已整合
// 移除 import FirebaseFirestoreSwift

// DatabaseService 類別：處理所有與 Firestore 的數據交互
class DatabaseService {
    
    // 取得 Firestore 資料庫實例
    private let db = Firestore.firestore()
    private let cookSpotsCollection = "cookSpots" // 假設您的私廚數據集合名稱
    private let ordersCollection = "orders"     // 假設您的訂單數據集合名稱
    
    // MARK: - 1. 讀取數據 (Fetch CookSpots)
    
    // 獲取所有私廚據點的數據
    func fetchCookSpots(completion: @escaping ([CookSpot]) -> Void) {
        
        db.collection(cookSpotsCollection)
            // 讀取所有數據
            .getDocuments { snapshot, error in
            
            if let error = error {
                print("Error fetching CookSpots: \(error.localizedDescription)")
                completion([])
                return
            }
            
            // 將 Firestore 文件轉換為我們的 CookSpot 結構
            let spots = snapshot?.documents.compactMap { doc -> CookSpot? in
                // 必須使用 try? 處理，因為 Firestore 的 data(as:) 仍然可能失敗
                do {
                    // 使用 Firestore 的 data(as:) 進行自動解碼 (現在已整合)
                    var spot = try doc.data(as: CookSpot.self)
                    spot.id = UUID(uuidString: doc.documentID)
                    return spot
                } catch {
                    print("Error decoding CookSpot: \(error)")
                    return nil
                }
            } ?? []
            
            completion(spots)
        }
    }
    
    // MARK: - 2. 寫入數據 (Submit Order)
    
    // 將完成的訂單提交到 Firestore
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
