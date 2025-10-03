import SwiftUI

// MARK: - 1. 主詳情頁視圖

struct CookSpotDetailView: View {
    
    // 確保 CookSpotDetailView 擁有 OrderManager 存取權限
    @EnvironmentObject var orderManager: OrderManager
    
    // 狀態：控制 Toast 顯示
    @State private var isToastVisible = false
    @State private var toastMessage = ""
    @State private var isCheckoutPresented: Bool = false // 用於 CheckoutView
    @State private var isCartPresented: Bool = false     // 用於 CartView 編輯
    
    // 接收點選的私廚數據
    let spot: CookSpot
    
    // 假設每個私廚的菜單都一樣
    let menuItems = MenuItem.sampleMenu
    
    // 篩選出用戶評價（前三喜歡/最新）
    var topReviews: [Review] {
        //
        return spot.reviews.filter { $0.rating >= 4.0 }.sorted(by: { $0.rating > $1.rating }).prefix(3).map { $0 }
    }
    
    // 假設前兩個菜色是熱賣商品 (實際應由後端提供數據)
    var hotItems: [MenuItem] {
        return menuItems.prefix(2).map { $0 }
    }

    var body: some View {
        
        // 使用 ZStack 讓購物車浮動在內容上方
        ZStack(alignment: .bottom) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // MARK: 區塊 1: 品牌簡介與拿手菜 (老闆大頭照下方)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            // 模擬老闆大頭照
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading) {
                                Text("\(spot.name) (\(spot.chef))") // 呈現商鋪老闆姓氏
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                    Text("拿手菜: \(spot.cuisine)") // 呈現拿手菜
                                }
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            }
                        }
                        .padding(.top)

                        // 簡介
                        Text(spot.description)
                            .font(.body)
                            .padding(.top, 5)

                        Divider()
                    }
                    .padding(.horizontal)
                    
                    
                    // MARK: 區塊 2: 今日熱賣商品 (垂直盒子 1)
                    if !hotItems.isEmpty {
                        VStack(alignment: .leading) {
                            Text("🔥 今日熱賣商品")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(hotItems, id: \.id) { item in
                                        HotItemCard(item: item) {
                                            orderManager.addItem(menuItem: item, quantity: 1)
                                            toastMessage = "已將「\(item.name)」加入購物車 🛒"
                                            isToastVisible = true
                                        }
                                        .environmentObject(orderManager)
                                    }
                                }
                                .padding(.horizontal, 5)
                            }
                        }
                        .padding(.leading)
                    }
                    
                    // MARK: 區塊 3: 用戶評價 (前三喜歡) (垂直盒子 4)
                    if !topReviews.isEmpty {
                        VStack(alignment: .leading) {
                            Text("⭐ 用戶好評推薦 (\(spot.rating, specifier: "%.1f") 評分)")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(topReviews) { review in
                                ReviewRow(review: review)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: 區塊 4: 完整菜單 (垂直盒子 3 - 主要菜色)
                    VStack(alignment: .leading) {
                        Text("📜 完整菜單")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(menuItems, id: \.id) { item in
                            MenuItemView(item: item) {
                                orderManager.addItem(menuItem: item, quantity: 1)
                                toastMessage = "已將「\(item.name)」加入購物車 🛒"
                                isToastVisible = true
                            }
                            .environmentObject(orderManager)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 增加底部空間
                    Spacer().frame(height: orderManager.totalQuantity > 0 ? 100 : 20)
                }
            } // ScrollView 結束
            
            // 浮動購物車面板
            floatingCartFooter
            
        } // ZStack 結束
        .navigationTitle("私廚主頁")
        .navigationBarTitleDisplayMode(.inline)
        
        // 🐞 修正：將所有 Sheet 邏輯放在 ZStack 的修飾符上
        .toast(message: toastMessage, isVisible: $isToastVisible)
        .sheet(isPresented: $isCheckoutPresented) {
            CheckoutView() // 結帳頁面
                .environmentObject(orderManager)
        }
        .sheet(isPresented: $isCartPresented) {
            CartView() // 購物車編輯頁面
                .environmentObject(orderManager)
        }
    }


    // 新增：底部浮動購物車視圖
    var floatingCartFooter: some View {
        
        // 只有當購物車有商品時才顯示
        Group {
            if orderManager.totalQuantity > 0 {
                VStack(spacing: 0) {
                    Divider() // 分隔線
                    HStack {
                        
                        // 1. 🐞 點擊總覽區塊：彈出 CartView 進行數量增減
                        Button {
                            isCartPresented = true
                        } label: {
                            HStack {
                                // 總數量和總價
                                VStack(alignment: .leading) {
                                    Text("\(orderManager.totalQuantity) 件商品")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(orderManager.totalPrice, format: .currency(code: "TWD").precision(.fractionLength(0)))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                // 箭頭圖標，提示這是可點擊的
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain) // 讓它看起來像文字區塊，而非按鈕
                        .padding(.trailing, 10)
                        
                        Divider()
                            .frame(height: 40)
                        
                        // 2. 結帳按鈕 (點擊開啟 CheckoutView)
                        Button {
                            isCheckoutPresented = true // 點擊結帳按鈕，彈出 CheckoutView
                        } label: {
                            Text("結帳去 (\(orderManager.totalQuantity))")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(width: 120, height: 40)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.thickMaterial) // 使用毛玻璃效果的背景
                }
                .transition(.move(edge: .bottom).combined(with: .opacity)) // 增加動畫
            }
        }
    }

} // CookSpotDetailView 結構結束

// MARK: - 2. 單一菜色項目視圖 (MenuItemView)

struct MenuItemView: View {
    
    // 追蹤購物車狀態
    @EnvironmentObject var orderManager: OrderManager
    
    let item: MenuItem
    let addItemAction: () -> Void
    
    // 計算屬性：獲取該商品在購物車中的當前數量
    var currentQuantity: Int {
        orderManager.items.first(where: { $0.menuItem == item })?.quantity ?? 0
    }
    
    var body: some View {
        HStack(alignment: .top) {
            
            // 🐞 修正：使用 AsyncImage 處理圖片載入
            if let imageURLString = item.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image // 圖片載入成功
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "xmark.octagon") // 載入失敗
                            .resizable()
                            .foregroundColor(.red)
                    } else {
                        ProgressView() // 載入中
                    }
                }
                .frame(width: 60, height: 60)
                .clipped() // 裁剪以確保圖片是方形
                .cornerRadius(8)
            } else {
                // 如果沒有 URL，顯示一個預設圖標
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue.opacity(0.7))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(item.isAvailable ? .primary : .gray)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                // 價格 Text (保持不變)
                Text(item.price, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                if item.isAvailable {
                    // 3. 替換原來的「點餐」按鈕為數量控制介面
                    if currentQuantity == 0 {
                        // 如果數量為 0，顯示「點餐」按鈕 (只負責 +1)
                        Button("點餐") {
                            addItemAction() // 呼叫父視圖傳遞的動作 (+1 和 Toast)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.small)
                    } else {
                        // 如果數量大於 0，顯示數量調整控制器
                        quantityControl
                    }
                } else {
                    Text("今日售罄")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        Divider() // 分隔線
    }
    
    // 新增：數量調整控制器 (包含 -, 數字, +)
    var quantityControl: some View {
        HStack(spacing: 12) {
            
            // 減少數量按鈕 (-)
            Button {
                // 呼叫 OrderManager 的 updateQuantity 函數，數量減 1
                if let cartItem = orderManager.items.first(where: { $0.menuItem == item }) {
                    orderManager.updateQuantity(item: cartItem, newQuantity: currentQuantity - 1)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            
            // 顯示當前數量
            Text("\(currentQuantity)")
                .font(.headline)
                .frame(minWidth: 20)
            
            // 增加數量按鈕 (+)
            Button {
                // 呼叫父視圖傳遞的動作，處理數量加 1 和 Toast
                addItemAction()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 3. 輔助 View：熱賣商品卡片 (HotItemCard)

struct HotItemCard: View {
    @EnvironmentObject var orderManager: OrderManager
    let item: MenuItem
    let addItemAction: () -> Void
    
    // 計算屬性：獲取該商品在購物車中的當前數量
    var currentQuantity: Int {
        orderManager.items.first(where: { $0.menuItem == item })?.quantity ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 圖片 (使用 AsyncImage 模擬)
            if let imageURLString = item.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "flame.fill").resizable().foregroundColor(.red).padding(15)
                    }
                }
                .frame(width: 120, height: 80)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 120, height: 80).cornerRadius(8)
            }

            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text(item.price, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                // 點擊按鈕 (簡化為直接增加)
                Button {
                    // 呼叫父視圖傳遞的動作，處理數量加 1 和 Toast
                    addItemAction()
                } label: {
                    Image(systemName: currentQuantity > 0 ? "checkmark.circle.fill" : "plus.circle.fill")
                        .foregroundColor(currentQuantity > 0 ? .green : .blue)
                }
            }
        }
        .frame(width: 120)
        .padding(.vertical, 5)
    }
}

// MARK: - 4. 輔助 View：評價單行 (ReviewRow)

struct ReviewRow: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(review.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(.blue)
                    .opacity(review.rating >= 4.0 ? 1 : 0) // 評分高才顯示讚
                // 🐞 修正：使用新的格式化語法
                Text(review.rating, format: .number.precision(.fractionLength(1)))
            }
            Text(review.comment)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
        Divider()
    }
}

// 預覽 (使用範例數據)
#Preview {
    // 預覽時必須手動創建 OrderManager 實例
    let previewOrderManager = OrderManager()
    
    return NavigationView {
        CookSpotDetailView(spot: CookSpot.sampleCookSpots.first!)
            // 必須將 OrderManager 注入預覽環境
            .environmentObject(previewOrderManager)
    }
}
