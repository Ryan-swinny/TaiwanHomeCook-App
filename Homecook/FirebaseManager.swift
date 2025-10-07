//
//  FirebaseManager.swift
//  Homecook
//
//  Created by Ryan.L on 10/7/2025.
//

import Foundation
import Combine

// ⚠️ 注意：這裡的 CookSpot 必須是主專案定義的結構體

class FirebaseManager: ObservableObject {
    
    let cookSpotsPublisher = PassthroughSubject<[CookSpot], Never>()
    
    @Published var isLoading = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startMockListener()
    }
    
    // 模擬 Firebase 的 addSnapshotListener 函數
    func startMockListener() {
        print("【Firebase Manager】開始模擬實時數據監聽...")
        
        // ⭐ 核心修正：將模擬延遲從 1.5 秒增加到 3.0 秒
        let delayInSeconds: Double = 3.0
        
        // 模擬數據延遲載入（例如，從網路獲取）
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) { [weak self] in
            guard let self = self else { return }
            
            // 模擬從 Firebase 獲取到最新的 CookSpot 列表
            let latestSpots = CookSpot.sampleCookSpots
            
            // 通過 Publisher 發佈數據給所有訂閱者
            self.cookSpotsPublisher.send(latestSpots)
            
            self.isLoading = false
            print("【Firebase Manager】模擬數據載入完成，已發佈 \(latestSpots.count) 筆數據。")
        }
        
        // 確保 Manager 訂閱自己
        cookSpotsPublisher
            .sink { _ in
                // 這裡可以處理任何與數據流結束相關的邏輯
            } receiveValue: { spots in
                // 這裡可以放置數據到達時的任何管理邏輯
            }
            .store(in: &cancellables)
    }
    
    // 備用：一次性獲取數據的模擬函數（用於對比）
    func fetchCookSpotsOnce(completion: @escaping ([CookSpot]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(CookSpot.sampleCookSpots)
        }
    }
}
