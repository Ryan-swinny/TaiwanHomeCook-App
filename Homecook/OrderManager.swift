import Foundation
import Combine

// CartItem 結構：代表購物車中一個菜色及其數量
// 這個結構必須在 OrderManager.swift 檔案的頂部，以便 OrderManager 存取。
struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let menuItem: MenuItem // 包含菜色本身的資訊
    var quantity: Int      // 使用者點了多少份
    
    // 方便計算此菜色的總價
    var totalItemPrice: Double {
        return menuItem.price * Double(quantity)
    }
}

// OrderManager 是一個中央狀態物件，將作為環境物件在整個 App 中共享
class OrderManager: ObservableObject {
    
    // @Published 屬性，當購物車內容改變時，所有觀察它的視圖都會自動更新
    @Published private(set) var items: [CartItem] = [] // private(set) 確保只能在 OrderManager 內部修改
    
    // 計算屬性：計算購物車內所有商品的總數量
    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    // 計算屬性：計算購物車內所有商品的總價
    var totalPrice: Double {
        items.reduce(0.0) { $0 + $1.totalItemPrice }
    }
    
    // MARK: - 核心動作：加入或增加商品
    
    func addItem(menuItem: MenuItem, quantity: Int = 1) {
        // 1. 檢查商品是否已存在於購物車 (通過檢查 MenuItem 的 ID)
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            // 2. 如果存在，則增加其數量
            items[index].quantity += quantity
        } else {
            // 3. 如果不存在，則添加新商品
            let newItem = CartItem(menuItem: menuItem, quantity: quantity)
            items.append(newItem)
        }
    }
    
    // MARK: - 核心動作：調整或移除商品
    
    // 移除單一 CartItem
    func removeItem(item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    // 調整單一商品的數量
    func updateQuantity(item: CartItem, newQuantity: Int) {
        // 使用 CartItem 的 ID 來找到要更新的項目
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        if newQuantity > 0 {
            // 如果新數量大於 0，則更新數量
            items[index].quantity = newQuantity
        } else {
            // 如果新數量小於或等於 0，則移除該商品
            items.remove(at: index)
        }
    }
    
    // 清空購物車（用於模擬結帳完成）
    func clearCart() {
        items = []
    }
}
