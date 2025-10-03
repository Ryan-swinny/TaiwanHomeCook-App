import Foundation

// 代表單一用戶評價的結構
struct Review: Identifiable, Codable {
    let id = UUID()
    let userName: String
    let comment: String
    let rating: Double // 評分 (1.0 到 5.0)
    let isPositive: Bool // 用於篩選「用戶評價（前三喜歡）」
}

// 範例評價數據
extension Review {
    static let sampleReviews = [
        Review(userName: "Jenny C.", comment: "紅燒肉的醬汁濃郁，超級下飯，吃了兩碗飯！", rating: 5.0, isPositive: true),
        Review(userName: "David L.", comment: "配送速度很快，但麻油雞湯有點太鹹了。", rating: 4.0, isPositive: true),
        Review(userName: "Amy W.", comment: "炒時蔬很新鮮，但是價格偏高。", rating: 3.5, isPositive: true),
        Review(userName: "Peter H.", comment: "瓜仔肉味道偏淡，沒有媽媽做的香。", rating: 3.0, isPositive: false)
    ]
}//
//  Review.swift
//  Homecook
//
//  Created by Ryan.L on 3/10/2025.
//

