//
//  AuthService.swift
//  Homecook
//
//  處理所有 Firebase 認證、註冊、登入及用戶資料載入（Profile）的核心服務。
//
//  Created by Ryan.L on 5/10/2025.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine
// 移除 import FirebaseFirestoreSwift 以避免模組錯誤

/// 處理所有 Firebase 認證（Auth）相關操作的服務層。
class AuthService: ObservableObject {
    
    // MARK: - User Profile Model
    
    // ⭐ 修正：將 UserProfile 結構體巢狀定義在 AuthService 內部，
    //    以避免與外部的任何可能衝突，並解決 'AuthService' is ambiguous 的問題。
    struct UserProfile: Codable, Identifiable {
        var id: String? // Firestore Document ID (手動賦值)
        let email: String
        let role: String // 用戶身份：顧客("我是顧客") 或 私廚("我是私廚")
        var address: String? // 配送地址（用於預填）
        var contactNumber: String? // 聯絡電話（用於預填）
        var cookerName: String? // 私廚名稱 (Cooker 專屬)
    }
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // MARK: - Published State
    
    @Published var user: User?
    @Published var currentProfile: UserProfile? // 用於結帳頁面預填
    
    private let userCollection = "users"
    private let cookerCollection = "cookers"

    init() {
        // 觀察認證狀態的變化
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let uid = user?.uid {
                print("【AUTH STATE】用戶狀態已變更，當前 UID: \(uid)")
                // 狀態變更時，立即載入 Profile
                self?.loadUserProfile(uid: uid)
            } else {
                print("【AUTH STATE】用戶已登出或未登入。")
                self?.currentProfile = nil // 登出時清空 Profile
            }
        }
    }
    
    // MARK: - Profile Management
    
    /// 載入 Firestore 中的用戶 Profile (跨用戶/私廚集合查找)
    func loadUserProfile(uid: String) {
        let userDocRef = db.collection(userCollection).document(uid)
        
        userDocRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                self.decodeProfile(document: document)
            } else {
                // 如果在 users 找不到，試試在 cookers 找 (處理兩種角色)
                self.db.collection(self.cookerCollection).document(uid).getDocument { doc, err in
                    if let doc = doc, doc.exists {
                        self.decodeProfile(document: doc)
                    } else {
                        print("Error: Profile not found for UID \(uid) in both collections.")
                    }
                }
            }
        }
    }

    // ⭐️ 修正：手動從 [String: Any] 字典中解析數據
    private func decodeProfile(document: DocumentSnapshot) {
        guard let data = document.data() else {
            print("Error: Document data is nil for ID \(document.documentID)")
            return
        }

        // 使用 Codable 嘗試自動解碼 (假設 Firestore 數據結構與 UserProfile 匹配)
        do {
            // 由於 UserProfile 現在是巢狀結構，這裡的解碼器可以正常工作
            var profile = try document.data(as: UserProfile.self)
            profile.id = document.documentID // 確保 ID 被手動賦值
            
            DispatchQueue.main.async {
                self.currentProfile = profile
                print("✅ 成功載入 Profile: \(profile.email)")
            }
        } catch {
            print("Error decoding UserProfile using Codable: \(error)")
            // 如果 Codable 失敗，退回到手動解析 (備用方案，保持代碼健壯性)
            let email = data["email"] as? String ?? ""
            let role = data["role"] as? String ?? ""
            
            let profile = UserProfile(
                id: document.documentID,
                email: email,
                role: role,
                address: data["address"] as? String,
                contactNumber: data["contactNumber"] as? String,
                cookerName: data["cookerName"] as? String
            )
            
            DispatchQueue.main.async {
                self.currentProfile = profile
                print("✅ 成功載入 Profile (手動解析): \(profile.email)")
            }
        }
    }
    
    // MARK: - 1. 註冊功能
    
    func register(role: UserRole, email: String, password: String, extraData: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let uid = authResult?.user.uid else {
                completion(.failure(AuthError.unknownError))
                return
            }
            
            // 寫入用戶資料到 Firestore
            self.createProfileInFirestore(uid: uid, role: role, email: email, extraData: extraData, completion: completion)
        }
    }
    
    private func createProfileInFirestore(uid: String, role: UserRole, email: String, extraData: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        
        let collection = (role == .cooker) ? cookerCollection : userCollection
        
        var data: [String: Any] = [
            "uid": uid,
            "email": email,
            "role": role.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]
        data.merge(extraData) { (_, new) in new }
        
        db.collection(collection).document(uid).setData(data) { error in
            if let error = error {
                print("Error writing profile to Firestore: \(error.localizedDescription)")
                // 修正：確保傳遞的是 Error
                completion(.failure(error))
            } else {
                print("Successfully created profile for \(role.rawValue) in Firestore.")
                completion(.success(()))
            }
        }
    }

    // MARK: - 2. 登錄功能
    
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        auth.signIn(withEmail: email, password: password) { authResult, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            print("【AUTH SUCCESS】用戶 \(authResult?.user.uid ?? "") 登錄成功。")
            completion(.success(()))
        }
    }
    
    // MARK: - 3. 登出功能
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - 錯誤類型定義

enum AuthError: Error {
    case unknownError
    case invalidRole
    
    var localizedDescription: String {
        switch self {
        case .unknownError:
            return "發生未知錯誤，請稍後再試。"
        case .invalidRole:
            return "無效的用戶身份。"
        }
    }
}
