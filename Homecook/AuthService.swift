//
//  AuthService.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine // ⭐ 修正 1：新增 Combine 模組導入

/// 處理所有 Firebase 認證（Auth）相關操作的服務層。
/// 它也負責在 Firestore 中創建初始的使用者/私廚資料。
// ⭐ 修正 2：確保繼承 ObservableObject
class AuthService: ObservableObject {
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // 用於發布當前用戶狀態給所有訂閱者
    @Published var user: User? // @Published 需要 Combine
    
    private let userCollection = "users"
    private let cookerCollection = "cookers"

    init() {
        // 觀察認證狀態的變化，並將當前用戶設置給 @Published 變數
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let uid = user?.uid {
                print("【AUTH STATE】用戶狀態已變更，當前 UID: \(uid)")
            } else {
                print("【AUTH STATE】用戶已登出或未登入。")
            }
        }
    }
    
    // MARK: - 1. 註冊功能 (保持不變)
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
            
            // 步驟二：認證成功後，將用戶資料寫入 Firestore
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
                completion(.failure(error))
            } else {
                print("Successfully created profile for \(role.rawValue) in Firestore.")
                completion(.success(()))
            }
        }
    }

    // MARK: - 2. 登錄功能 (保持不變)
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
    
    // MARK: - 3. 登出功能 (保持不變)
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - 錯誤類型定義 (保持不變)
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
