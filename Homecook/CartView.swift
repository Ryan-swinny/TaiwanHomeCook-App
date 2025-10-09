import SwiftUI

struct CartView: View {
    
    // 透過環境物件存取購物車管理器
    @EnvironmentObject var orderManager: OrderManager
    
    // 視圖的顯示狀態：用來關閉購物車頁面
    @Environment(\.dismiss) var dismiss
    
    // 狀態變數：控制 CheckoutView 是否彈出
    @State private var isCheckoutPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                
                // 1. 購物車商品列表
                if orderManager.items.isEmpty {
                    Spacer()
                    Text("🛒 您的購物車目前是空的。")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("快去附近私廚看看有什麼好菜吧！")
                    Spacer()
                } else {
                    List {
                        // 顯示每一個已點的 CartItem
                        ForEach(orderManager.items) { item in
                            CartItemRow(item: item)
                                .environmentObject(orderManager)
                        }
                        .onDelete(perform: deleteItems) // 啟用左滑刪除功能
                        
                        // 總計區塊
                        totalSummary
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
                
                // 2. 結帳按鈕 (浮動在底部)
                checkoutButton
            }
            .navigationTitle("我的訂單 (\(orderManager.totalQuantity))")
            .toolbar {
                // 關閉按鈕，讓使用者可以返回
                Button("關閉") {
                    dismiss()
                }
            }
            // 使用 sheet 方式彈出 CheckoutView
            .sheet(isPresented: $isCheckoutPresented) {
                // 修正：這裡的 CheckoutView 確保環境物件的傳遞
                CheckoutView()
                    .environmentObject(orderManager)
                    // 這裡的 AuthService() 確保傳遞給 CheckoutView
                    .environmentObject(AuthService())
            }
        }
        // 修正：移除這裡可能存在的隱式 return 關鍵字
    }
    
    // 購物車總計的獨立視圖
    var totalSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack {
                Text("商品總計")
                    .foregroundColor(.secondary)
                Spacer()
                // 使用新的格式化語法
                Text(orderManager.totalPrice, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    .fontWeight(.medium)
            }
            HStack {
                Text("配送費")
                    .foregroundColor(.secondary)
                Spacer()
                Text("$60") // 假設固定配送費
                    .fontWeight(.medium)
            }
            Divider()
            HStack {
                Text("總金額")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                // 使用新的格式化語法
                Text(orderManager.totalPrice + 60, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical)
    }
    
    // 底部結帳按鈕
    var checkoutButton: some View {
        Button {
            // 點擊按鈕，設定狀態為 true，彈出 CheckoutView
            isCheckoutPresented = true
            
            let finalPrice = orderManager.totalPrice + 60
            print("準備結帳，總金額: $\(finalPrice)")
            
        } label: {
            Text("立即結帳")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .disabled(orderManager.items.isEmpty) // 如果購物車是空的，按鈕不可點選
    }
    
    // 左滑刪除方法
    func deleteItems(offsets: IndexSet) {
        // 從 IndexSet 找到要刪除的 CartItem 實例
        if let index = offsets.first {
            let itemToDelete = orderManager.items[index]
            orderManager.removeItem(item: itemToDelete)
        }
    }
}

// MARK: - CartItemRow 獨立視圖

// 獨立視圖：顯示購物車中單一商品及其數量控制
struct CartItemRow: View {
    @EnvironmentObject var orderManager: OrderManager
    let item: CartItem // CartItem 包含 MenuItem 和 quantity
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill") // 這裡可以放商品圖片
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue.opacity(0.7))
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Text(item.menuItem.name)
                    .font(.headline)
                // 使用新的格式化語法
                Text(item.menuItem.price, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // ⭐ 修正：使用自定義的加/減按鈕取代 Stepper (Level 4A)
            HStack(spacing: 15) {
                Button {
                    // 減量
                    orderManager.updateQuantity(item: item, newQuantity: item.quantity - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.plain)
                .tint(.orange)
                
                Text("\(item.quantity)")
                    .font(.headline)
                    .frame(minWidth: 20)
                
                Button {
                    // 加量
                    orderManager.updateQuantity(item: item, newQuantity: item.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .tint(.orange)
            }
            
            // 該商品的總價
            Text(item.totalItemPrice, format: .currency(code: "TWD").precision(.fractionLength(0)))
                .font(.callout)
                .fontWeight(.bold)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    // 預覽時必須提供 OrderManager
    let previewManager = OrderManager()
    previewManager.addItem(menuItem: MenuItem.sampleMenu[0], quantity: 2)
    previewManager.addItem(menuItem: MenuItem.sampleMenu[2], quantity: 1)
    
    // 修正：明確建立 AuthService 實例來解決 Ambiguous use of 'init()'
    let authService: AuthService = AuthService()
    
    return CartView()
        .environmentObject(previewManager)
        // 預覽也需要 AuthService，即使它是空的
        .environmentObject(authService)
}
