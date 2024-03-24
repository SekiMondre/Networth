import SwiftUI

struct MainView: View {
    
    var body: some View {
        TabView {
            AssetAllocationView(controller: AssetAllocationController(type: .crypto))
                .tabItem {
                    Image(systemName: "doc")
                    Text("Crypto")
                }
            ImpermanentLossView()
                .tabItem {
                    Image(systemName: "doc")
                    Text("Impermanent Loss")
                }
        }
    }
}

#Preview {
    MainView()
}
