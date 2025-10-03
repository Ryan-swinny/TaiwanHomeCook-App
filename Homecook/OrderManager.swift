import Foundation
import Combine
import FirebaseFirestore // 🐞 修正：保持這個導入，因為它需要 FieldValue.serverTimestamp()

// CartItem 結構：代表購物車中一個菜色及其數量
// ... (CartItem 結構保持不變) ...
struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let menuItem: MenuItem
    var quantity: Int
    
    var totalItemPrice: Double {
        return menuItem.price * Double(quantity)
    }
}

// OrderManager 是一個中央狀態物件，將作為環境物件在整個 App 中共享
class OrderManager: ObservableObject {
    
    // 引入 DatabaseService 實例，用於後端數據操作
    private let dbService = DatabaseService()
    
    @Published private(set) var items: [CartItem] = []
    
    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    var totalPrice: Double {
        items.reduce(0.0) { $0 + $1.totalItemPrice }
    }
    
    // MARK: - 核心動作：加入/調整/移除商品 (保持不變)
    func addItem(menuItem: MenuItem, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            items[index].quantity += quantity
        } else {
            let newItem = CartItem(menuItem: menuItem, quantity: quantity)
            items.append(newItem)
        }
    }
    
    func removeItem(item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func updateQuantity(item: CartItem, newQuantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if newQuantity > 0 {
            items[index].quantity = newQuantity
        } else {
            items.remove(at: index)
        }
    }
    
    func clearCart() {
        items = []
    }
    
    // MARK: - 訂單提交邏輯 (連線到 Firestore)
    
    // 將 Swift 數據結構轉換為 Firestore 接受的 [String: Any] 格式
    func packageOrderData(address: String, contact: String, payment: String) -> [String: Any] {
        let itemsData = items.map { item -> [String: Any] in
            return [
                "menuItemId": item.menuItem.id.uuidString,
                "name": item.menuItem.name,
                "price": item.menuItem.price,
                "quantity": item.quantity,
                "total": item.totalItemPrice
            ]
        }
        
        let orderData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "totalPrice": self.totalPrice,
            "deliveryFee": 60.0,
            "finalAmount": self.totalPrice + 60.0,
            "address": address,
            "contact": contact,
            "paymentMethod": payment,
            "items": itemsData,
            "status": "Pending"
        ]
        return orderData
    }
    
    // 實際提交訂單的方法
    func finalSubmitOrder(address: String, contact: String, payment: String, completion: @escaping (Bool) -> Void) {
        let data = packageOrderData(address: address, contact: contact, payment: payment)
        
        dbService.submitOrder(orderData: data) { success in
            if success {
                self.clearCart() // 提交成功後清空購物車
            }
            completion(success)
        }
    }
}
