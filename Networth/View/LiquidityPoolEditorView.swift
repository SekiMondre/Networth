import SwiftUI

struct LiquidityPoolEditorView: View {
    
    @State private var tokenA = ""
    @State private var aPriceAtDeposit = ""
    
    @State private var tokenB = ""
    @State private var bPriceAtDeposit = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Token A", text: $tokenA)
                TextField("Price A", text: $aPriceAtDeposit)
                    .keyboardType(.decimalPad)
                TextField("Token B", text: $tokenB)
                TextField("Price B", text: $bPriceAtDeposit)
                    .keyboardType(.decimalPad)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add item")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        withAnimation {
                            save()
//                            dismiss()
                        }
                    }
                    .disabled(true)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
//                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        
    }
}

#Preview {
    LiquidityPoolEditorView()
}
