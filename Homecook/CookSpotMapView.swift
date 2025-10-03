import SwiftUI
import MapKit // 導入 MapKit 框架

struct CookSpotMapView: View {
    
    // 接收篩選後的私廚列表
    let nearbyCookSpots: [CookSpot]
    
    // 接收使用者當前位置
    let userLocation: CLLocation
    
    // 1. Map 的視角狀態必須使用 MapCameraPosition (取代舊的 MKCoordinateRegion)
    @State private var cameraPosition: MapCameraPosition
    
    // 初始化方法：設定地圖的初始中心點和縮放比例
    init(nearbyCookSpots: [CookSpot], userLocation: CLLocation) {
        self.nearbyCookSpots = nearbyCookSpots
        self.userLocation = userLocation
        
        // 根據使用者當前位置初始化地圖區域
        let initialRegion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: userLocation.coordinate,
                // 設定縮放比例：這裡使用 0.015 經緯度跨度，約 2 公里視野
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
        )
        // 將初始區域賦值給 @State 變數
        _cameraPosition = State(initialValue: initialRegion)
    }
    
    var body: some View {
        
        // 使用新的 Map 初始化方法：Map(position:content:)
        Map(position: $cameraPosition) {
            
            // 標註一：使用者自己的位置 (藍點)
            // UserAnnotation 是 MapKit 框架中內建的用戶位置標記
            UserAnnotation()
            
            // 標註二：附近的私廚據點
            // 修正：使用 Annotation 取代 MapAnnotation
            ForEach(nearbyCookSpots, id: \.identifiableId) { spot in
                
                // 標記的座標是私廚的經緯度
                Annotation(spot.name, coordinate: spot.coordinate) {
                    
                    // 客製化的地圖標記外觀
                    VStack(spacing: 0) {
                        Text("🏡") // 房屋符號作為主要標記
                            .font(.title)
                        
                        // 標籤：私廚名稱
                        Text(spot.name)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.orange)
                            .cornerRadius(8)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.bottom, 15)
                }
            }
        }
        // 允許使用者互動，並添加控制按鈕
        .mapControls {
            MapUserLocationButton() // 快速回到用戶位置的按鈕
            MapCompass()
        }
    }
}
