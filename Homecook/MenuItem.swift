import Foundation

// 代表單一菜色的資料結構
struct MenuItem: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    let name: String
    let description: String
    let price: Double // 菜色價格
    let isAvailable: Bool // 是否今日供應
    let imageURL: String? // 🐞 修正：新增 imageURL 屬性
}

// 範例菜單數據 (使用公開的圖片 URL 進行模擬)
extension MenuItem {
    static let sampleMenu: [MenuItem] = [
        // 範例圖片 URL 確保 App 可以從網路載入
        MenuItem(name: "祖傳紅燒肉 (限量)", description: "肥而不膩，入口即化，林阿嬤的招牌。", price: 280.0, isAvailable: true, imageURL: "https://images.unsplash.com/photo-1546069901-ba95155f52a7?w=100"),
        MenuItem(name: "家常瓜仔肉", description: "鹹香下飯，傳統古早味。", price: 180.0, isAvailable: true, imageURL: "https://images.unsplash.com/photo-1563729781498-84225a07c1fe?w=100"),
        MenuItem(name: "麻油雞湯", description: "暖身補氣，使用在地土雞。", price: 320.0, isAvailable: true, imageURL: "https://images.unsplash.com/photo-1588147822453-433d7b884d59?w=100"),
        MenuItem(name: "炒時蔬", description: "當日新鮮採摘的清炒時令蔬菜。", price: 120.0, isAvailable: false, imageURL: nil)
    ]
}
