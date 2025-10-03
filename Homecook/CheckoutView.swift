import SwiftUI
import Foundation

struct CheckoutView: View {
    
    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.dismiss) var dismiss
    
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
            }
            .navigationTitle("確認訂單")
            .toolbar {
                Button("取消") {
                    dismiss()
                }
            }
            
            // 底部送出按鈕
            VStack {
                Button("確認並送出訂單") {
                    submitOrder()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isFormValid) // 如果表單無效則禁用按鈕
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
    
    // 訂單送出邏輯
    func submitOrder() {
        // 呼叫 OrderManager 的最終提交方法，將表單數據傳遞給 OrderManager 處理
        orderManager.finalSubmitOrder(
            address: deliveryAddress,
            contact: contactNumber,
            payment: selectedPayment
        ) { success in
            
            // 成功提交到 Firestore
            if success {
                print("【FIREBASE SUCCESS】訂單已成功寫入 Firestore！")
                // 觸發跳轉到 OrderConfirmationView
                isOrderSubmitted = true
            } else {
                // 顯示錯誤或保持在當前頁面
                print("【FIREBASE FAILED】訂單提交失敗。")
            }
        }
    }
}

#Preview {
    let manager = OrderManager()
    manager.addItem(menuItem: MenuItem.sampleMenu[0], quantity: 1)
    manager.addItem(menuItem: MenuItem.sampleMenu[2], quantity: 1)
    
    return CheckoutView()
        .environmentObject(manager)
}
