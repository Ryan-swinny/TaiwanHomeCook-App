import Foundation
import CoreLocation

// Codable 讓這個結構可以輕鬆地被儲存和讀取 (例如從後端資料庫)
struct CookSpot: Identifiable, Codable {
    
    // 修正一：讓 id 成為可選類型 (UUID?)，這樣 Codable 在解碼時如果沒有這個欄位也不會報錯。
    // 在真實的後端專案中，id 通常是由伺服器賦予，所以設為可選是常見做法。
    var id: UUID? // 使用 var 或將其設為 Codable Required 屬性

    // 廚師/據點的基本資訊
    let name: String            // 例如: 王媽媽的私房菜
    let chef: String            // 例如: 王雪梅
    let cuisine: String         // 例如: 台灣家常菜
    let description: String     // 例如: 祖傳三代的紅燒肉
    let rating: Double          // 評分 (例如: 4.8)
    let priceRange: String      // 價格區間 (例如: $150-$300)
    
    // 關鍵資訊：私廚的地理位置
    let latitude: Double
    let longitude: Double
    
    // 新增：該私廚的所有評價
    let reviews: [Review]
    
    // 方便計算距離的計算屬性
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 修正二：提供一個計算屬性來保證每個 CookSpot 都有一個 UUID
    // 這是為了在 ForEach (如 ContentView 和 CookSpotMapView) 中使用時，
    // 即使 id 是 nil，也能提供一個唯一的識別碼。
    var identifiableId: UUID {
        return id ?? UUID()
    }
}

// 範例資料 (台灣幾個假想的私廚據點)
extension CookSpot {
    static let sampleCookSpots = [
        CookSpot(
            id: UUID(), // 修正三：為每個範例數據手動賦予一個唯一的 id
            name: "林阿嬤的古早味",
            chef: "林玉枝",
            cuisine: "台式傳統",
            description: "費時慢燉的瓜仔肉，限量供應！",
            rating: 4.9,
            priceRange: "中價位",
            // 臺北 101 附近
            latitude: 25.0350,
            longitude: 121.5650,
            reviews: Review.sampleReviews // 🐞 修正：拼寫錯誤，確保所有評價都被加入
        ),
        CookSpot(
            id: UUID(), // 修正三：為每個範例數據手動賦予一個唯一的 id
            name: "周老師的健康廚房",
            chef: "周文華",
            cuisine: "養生輕食",
            description: "低卡低油的健康便當，上班族最愛。",
            rating: 4.5,
            priceRange: "低價位",
            // 臺北車站附近
            latitude: 25.0478,
            longitude: 121.5175,
            reviews: Review.sampleReviews // 🐞 修正：補上 reviews 屬性
        ),
        CookSpot(
            id: UUID(), // 修正三：為每個範例數據手動賦予一個唯一的 id
            name: "陳家的川味麻辣",
            chef: "陳莉萍",
            cuisine: "川菜",
            description: "挑戰味蕾的重慶小麵與麻辣香鍋。",
            rating: 4.2,
            priceRange: "高價位",
            // 永和區附近
            latitude: 25.0064,
            longitude: 121.5135,
            reviews: Review.sampleReviews // 🐞 修正：補上 reviews 屬性
        )
    ]
}
