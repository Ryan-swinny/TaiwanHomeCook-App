//
//  ContentView.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import SwiftUI
import CoreLocation
import Combine // 確保導入 Combine

struct ContentView: View {
    
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    // 儲存實時數據
    @State private var allCookSpots: [CookSpot] = []
    
    // 追蹤數據訂閱
    @State private var cancellable: AnyCancellable?
    
    // 根據定位結果，篩選出附近的私廚
    var nearbyCookSpots: [CookSpot] {
        locationManager.filterCookSpots(allSpots: allCookSpots)
    }
    
    // MARK: - Body View
    var body: some View {
        
        // 檢查定位授權狀態，優先處理「拒絕」和「未決定」的狀態
        let mainContent: AnyView = {
            switch locationManager.authorizationStatus {
            case .denied, .restricted:
                return AnyView(permissionDeniedView)
                
            case .notDetermined, .authorizedAlways, .authorizedWhenInUse, .none:
                // 這裡我們需要檢查數據是否載入完成
                if firebaseManager.isLoading {
                    // ⭐ 顯示 RamenLoadingView (麵條升降動畫)
                    return AnyView(RamenLoadingView())
                } else {
                    return AnyView(mainTabView)
                }

            @unknown default:
                return AnyView(Text("未知狀態，請檢查 App 設定。"))
            }
        }()
        
        // 將 onAppear 應用在最終的 View 實體上
        return mainContent
            .onAppear {
                self.setupCookSpotsSubscription()
            }
    }
    
    // 設置 Combine 數據訂閱
    func setupCookSpotsSubscription() {
        // 清除舊的訂閱，確保只訂閱一次
        cancellable?.cancel()
        
        // 訂閱 Manager 發佈者
        cancellable = firebaseManager.cookSpotsPublisher
            .receive(on: DispatchQueue.main) // 確保在主執行緒上更新 UI
            .sink { latestSpots in // 移除 [weak self]，因為 ContentView 是 Struct
                // 當收到新數據時，更新 @State 屬性
                self.allCookSpots = latestSpots
            }
    }
    
    // MARK: - Main Tab View (已授權或等待中)
    var mainTabView: some View {
        NavigationView {
            
            // 使用 TabView 讓使用者可以在「列表」和「地圖」之間切換
            TabView {
                
                // 標籤一：列表視圖
                listTabView
                    .tabItem {
                        Label("列表", systemImage: "list.bullet.clipboard.fill")
                    }
                
                // 標籤二：地圖視圖
                mapTabView
                    .tabItem {
                        Label("地圖", systemImage: "map.fill")
                    }
            }
            .navigationTitle("台灣 Home Cook")
            .navigationBarTitleDisplayMode(.inline) // 確保標題位置一致
        }
    }
    
    // MARK: - List View Tab
    var listTabView: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.bottom)
            
            // 檢查是否已取得位置
            if let userLocation = locationManager.location {
                // 如果已定位，則顯示列表
                List {
                    Text("附近 \(locationManager.searchRadius / 1000, specifier: "%.0f") 公里內的美食：")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .listRowSeparator(.hidden)
                        .padding(.top)
                    
                    // 核心修正：避免在載入完成前顯示「抱歉」訊息
                    if nearbyCookSpots.isEmpty {
                        VStack(alignment: .center) {
                            if firebaseManager.isLoading {
                                // 數據仍在載入中，顯示進度條 (狀態 B)
                                ProgressView("正在篩選附近美食...")
                                    .font(.subheadline)
                                    .padding(.vertical, 30)
                            } else {
                                // 數據載入完成，但列表為空 (狀態 C)
                                Text("抱歉！您的附近目前沒有私房菜上線。")
                                Text("試試調整搜尋半徑！")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        
                    } else {
                        // 使用 NavigationLink 包裹 CookSpotRow，點擊時進入詳情頁
                        ForEach(nearbyCookSpots, id: \.identifiableId) { spot in
                            NavigationLink {
                                CookSpotDetailView(spot: spot)
                                    .environmentObject(orderManager)
                            } label: {
                                CookSpotRow(spot: spot, userLocation: userLocation)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
            } else {
                Spacer()
                // 顯示等待定位的狀態 (狀態 A)
                locationStatusView
                Spacer()
            }
        }
    }
    
    // MARK: - Map View Tab
    var mapTabView: some View {
        // 地圖只需要用戶位置和權限
        if let userLocation = locationManager.location {
            return AnyView(
                CookSpotMapView(
                    nearbyCookSpots: nearbyCookSpots,
                    userLocation: userLocation.coordinate
                )
            )
        } else {
            return AnyView(
                VStack {
                    Spacer()
                    Text("地圖載入中...")
                    locationStatusView
                    Spacer()
                }
            )
        }
    }
    
    // MARK: - Helper Views
    
    // 輔助視圖：定位權限被拒絕時的畫面
    var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            
            Text("無法存取您的位置")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("請前往設定開啟定位權限，才能找到附近的私房菜！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Call-to-Action 按鈕：引導用戶
            Button("重新請求權限") {
                locationManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
    
    // 輔助視圖：等待定位的狀態
    var locationStatusView: some View {
        VStack {
            Text("正在等待您的 GPS 位置...")
                .foregroundColor(.gray)
            // 顯示授權狀態
            Text("定位授權狀態：\(locationManager.authorizationStatus.map { String($0.statusDescription) } ?? "等待中")")
                .font(.subheadline)
                .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse ? .green : .red)
                .padding(.top, 5)
        }
    }
    
    // 頂部標題視圖
    var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("🏠 回家吃飯")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 修正：更精確地反映當前狀態
                Text(locationManager.location != nil ? "已在 \(locationManager.searchRadius / 1000, specifier: "%.0f") 公里內搜尋" : "請允許定位以搜尋附近美食")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

// ⭐ 輔助 View: 載入畫面 (RamenLoadingView - 模擬麵條升降動畫)
struct RamenLoadingView: View {
    
    // 核心修正: 替換為指定的單一提示
    private let singleHint = "請稍後，正在為您找到合適的家廚"
    
    // 模擬麵條和配料上下移動的狀態
    @State private var offsetUp: Bool = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // 1. 麵條與配料動畫模擬
            ZStack {
                // 配料：雞蛋 (使用 circle.fill 模擬)
                Image(systemName: "circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .overlay(
                        Circle().fill(Color.orange).frame(width: 15, height: 15)
                    )
                    .offset(x: -25, y: offsetUp ? -110 : -100)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.2), value: offsetUp)
                
                // 配料：蔬菜 (使用三角形模擬)
                Image(systemName: "triangle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.green)
                    .offset(x: 30, y: offsetUp ? -70 : -60)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5), value: offsetUp)

                // 麵條：使用多個線條模擬
                HStack(spacing: 5) {
                    ForEach(0..<5) { index in
                        Capsule() // 使用 Capsule 模擬粗麵條
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: 5, height: 100)
                            .offset(y: offsetUp ? -100 : 0) // 整體升降
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: offsetUp)
                    }
                }
                .frame(height: 100)
                .mask(
                    Rectangle() // 使用矩形遮罩讓它看起來是從碗裡出來的
                )
                
                // 核心修正: 替換矩形為自定義的 BowlShape
                BowlShape()
                    .fill(Color.white)
                    .frame(width: 150, height: 80) // 增加高度以容納曲線
                    .overlay(
                        BowlShape() // 碗的邊緣 (線條)
                            .stroke(Color.black.opacity(0.8), lineWidth: 4)
                            .frame(width: 150, height: 80)
                    )
                    .offset(y: 50)
            }
            .frame(height: 150)
            .onAppear {
                offsetUp = true
            }
            .padding(.bottom, 30)

            // 2. 幽默提示
            Text(singleHint) // ⭐ 核心修正: 使用單一提示
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // 3. 標準進度條
            ProgressView()
                .padding(.top, 10)
            
            Spacer()
        }
        // ⭐ 核心修正: 添加溫暖的背景色
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 填充整個螢幕
        .background(Color.warmSkintone.edgesIgnoringSafeArea(.all)) // 設置背景色並忽略安全區域
    }
}


// 獨立的視圖：用於顯示單個私廚的資訊行 (CookSpotRow)
struct CookSpotRow: View {
    let spot: CookSpot
    let userLocation: CLLocation
    
    // 計算使用者到私廚的距離
    var distance: String {
        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        
        // 格式化距離：如果大於 1000 公尺顯示為「公里」，否則顯示為「公尺」
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        return formatter.string(fromValue: distanceInMeters, unit: .meter)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "house.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(spot.name)
                    .font(.headline)
                Text("\(spot.cuisine) • \(spot.description)")
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(spot.rating, specifier: "%.1f")")
                        .font(.caption)
                    Text("•")
                    Text(spot.priceRange)
                        .font(.caption)
                }
            }
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(distance)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Text("距離")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 擴展 CLAuthorizationStatus，讓它可以直接輸出中文描述 (保持不變)
extension CLAuthorizationStatus {
    var statusDescription: String {
        switch self {
        case .authorizedWhenInUse: return "已授權 (App 使用期間)"
        case .denied: return "已拒絕"
        case .notDetermined: return "尚未決定"
        case .restricted: return "受限"
        case .authorizedAlways: return "永遠允許"
        @unknown default: return "未知狀態"
        }
    }
}

// ⭐ 新增: 自定義 Shape 實現完美的碗型弧線
struct BowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // 1. 碗的頂部 (直線)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // 2. 碗的底部 (二次貝塞爾曲線，模擬圓弧)
        path.addQuadCurve(
            to: CGPoint(x: 0, y: 0),
            control: CGPoint(x: width / 2, y: height * 1.5) // 將控制點拉低，製造向下的深度和圓弧
        )
        
        return path
    }
}


// ⭐ 核心修正: 擴展 Color 增加一個溫暖的肌膚色
extension Color {
    static let silverMist = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let warmSkintone = Color(red: 0.96, green: 0.94, blue: 0.90) // 柔和的米色/淺暖黃，類似 #F5F0E6
}

#Preview {
    // 預覽時必須提供所有 EnvironmentObject
    let previewOrderManager = OrderManager()
    let previewLocationManager = LocationManager()
    let previewFirebaseManager = FirebaseManager()
    
    return ContentView()
        .environmentObject(previewOrderManager)
        .environmentObject(previewLocationManager)
        .environmentObject(previewFirebaseManager)
}
