import SwiftUI
import Foundation

struct CheckoutView: View {
    
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    // ⭐ 新增：用於選項 B 的狀態追蹤 (載入與錯誤)
    @State private var isSubmitting: Bool = false
    @State private var submissionError: String?
    
    // 追蹤訂單是否送出
    @State private var isOrderSubmitted: Bool = false
    
    // 結帳所需的輸入狀態
    @State private var deliveryAddress: String = ""
    @State private var contactNumber: String = ""
    @State private var selectedPayment: String = "貨到付款"
    
    let paymentOptions = ["貨到付款", "信用卡 / Apple Pay", "LINE Pay"]
    
    var finalPrice: Double {
        orderManager.totalPrice + 60
    }
    
    var isFormValid: Bool {
        !deliveryAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !contactNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. 配送資訊
                Section(header: Text("配送資訊")) {
                    TextField("完整配送地址 (必填)", text: $deliveryAddress)
                    TextField("聯絡電話 (必填)", text: $contactNumber)
                        .keyboardType(.phonePad)
                }
                
                // MARK: - 2. 支付方式
                Section(header: Text("支付方式")) {
                    Picker("選擇支付方式", selection: $selectedPayment) {
                        ForEach(paymentOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // MARK: - 3. 訂單總結
                Section(header: Text("訂單總結")) {
                    HStack {
                        Text("商品總金額")
                        Spacer()
                        Text(orderManager.totalPrice, format: .currency(code: "TWD").precision(.fractionLength(0)))
                    }
                    HStack {
                        Text("配送費")
                        Spacer()
                        Text("$60")
                    }
                    Divider()
                    HStack {
                        Text("應付總額")
                            .font(.headline)
                        Spacer()
                        Text(finalPrice, format: .currency(code: "TWD").precision(.fractionLength(0)))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                // ⭐ 新增：錯誤訊息顯示 (Option B)
                if let error = submissionError {
                    Text("訂單提交失敗：\(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("確認訂單")
            .toolbar {
                Button("取消") {
                    dismiss()
                }
            }
            // 預填資料 (Option A)
            .onAppear {
                self.prefillUserData()
            }
            
            // 底部送出按鈕
            VStack {
                Button {
                    submitOrder()
                } label: {
                    if isSubmitting {
                        ProgressView() // 載入中動畫
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("確認並送出訂單")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                // 修正：加入 isSubmitting 判斷，避免在載入時改變背景
                .background(isFormValid && !isSubmitting ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                // 修正：當表單無效或正在提交時禁用按鈕
                .disabled(!isFormValid || isSubmitting)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // 使用 navigationDestination 處理送出後的跳轉
            .navigationDestination(isPresented: $isOrderSubmitted) {
                // 訂單送出後，跳轉到確認頁面
                OrderConfirmationView()
            }
        }
    }
    
    // ⭐ 修正：預填用戶資料的邏輯
    func prefillUserData() {
        if let profile = authService.currentProfile {
            // 優先使用 Profile 中的資料進行預填
            if let address = profile.address, !address.isEmpty {
                self.deliveryAddress = address
            }
            if let contact = profile.contactNumber, !contact.isEmpty {
                self.contactNumber = contact
            }
            
            // 如果用戶是私廚 (cooker)，可以預設使用註冊 email 作為聯絡方式
            if profile.role == "我是私廚" {
                // 這裡可以根據你的數據結構決定如何預填
            }
        }
    }
    
    // ⭐ 修正：訂單送出邏輯 (加入載入和錯誤狀態管理 - Option B)
    func submitOrder() {
        isSubmitting = true
        submissionError = nil
        
        orderManager.finalSubmitOrder(
            address: deliveryAddress,
            contact: contactNumber,
            payment: selectedPayment
        ) { success in
            
            DispatchQueue.main.async {
                self.isSubmitting = false // 無論成功或失敗，都停止載入
                
                if success {
                    print("【FIREBASE SUCCESS】訂單已成功寫入 Firestore！")
                    self.isOrderSubmitted = true
                } else {
                    // 假設 OrderManager 內部沒有返回詳細錯誤，給出通用提示
                    self.submissionError = "網路連線或伺服器錯誤，請稍後再試。"
                    print("【FIREBASE FAILED】訂單提交失敗。")
                }
            }
        }
    }
}

#Preview {
    let manager = OrderManager()
    manager.addItem(menuItem: MenuItem.sampleMenu[0], quantity: 1)
    manager.addItem(menuItem: MenuItem.sampleMenu[2], quantity: 1)
    
    // 必須為預覽環境注入 AuthService，即使它是空的
    return CheckoutView()
        .environmentObject(manager)
        .environmentObject(AuthService()) // 注入 AuthService
}
