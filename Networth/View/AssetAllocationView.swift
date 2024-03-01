import SwiftUI

//struct AssetAllocationView: View {
//    
//    var body: some View {
//        VStack {
//            
//        }
//    }
//}

struct PieSlice: Identifiable, Hashable {
    let text: String
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
}

struct PieChartSlice: View {
    
    let slice: PieSlice
    
    private let textDisplacement: CGFloat = 1.17
    private let angleOffset = Angle(degrees: -90)
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width: CGFloat = min(geometry.size.width, geometry.size.height)
                let height = width
                let center = CGPoint(x: width * 0.5, y: height * 0.5)
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: width * 0.5,
                    startAngle: angleOffset + slice.startAngle,
                    endAngle: angleOffset + slice.endAngle,
                    clockwise: false)
            }
            .fill(slice.color)
            
            Text(slice.text)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .multilineTextAlignment(.center)
                .position(
                    x: geometry.size.width * 0.5 + geometry.size.width * 0.5 * textDisplacement * rotationFactorX,
                    y: geometry.size.height * 0.5 + geometry.size.width * 0.5 * textDisplacement * rotationFactorY)
                .foregroundColor(.white)
//            Path {
//                $0.move(to: CGPoint(
//                    x: geometry.size.width * 0.5,
//                    y: geometry.size.height * 0.5))
//                $0.addLine(to: CGPoint(
//                    x: geometry.size.width * 0.5 + geometry.size.width * 0.5 * textDisplacement * rotationFactorX,
//                    y: geometry.size.height * 0.5 + geometry.size.width * 0.5 * textDisplacement * rotationFactorY))
//            }
//            .stroke(.black)
        }
    }
    private var rotationFactorX: Double {
        cos(angleOffset.radians + (slice.startAngle + slice.endAngle).radians / 2)
    }
    private var rotationFactorY: Double {
        sin(angleOffset.radians + (slice.startAngle + slice.endAngle).radians / 2)
    }
}

struct PieChartOld: View {
    
    private let slices: [PieSlice]
    
    init(allocations: [Allocation]) {
        let totalValue = allocations.map { $0.value }.reduce(0, +)
        var currentDegrees: Double = 0
        var slices: [PieSlice] = []
        for i in 0..<allocations.count {
            let asset = allocations[i]
            let normalizedValue = asset.value / totalValue
            let deltaDegrees = normalizedValue * 360
            let text = String(format: "%.2f%%", normalizedValue * 100) + "\n\(asset.name)"
            slices.append(PieSlice(
                text: text,
                startAngle: Angle(degrees: currentDegrees),
                endAngle: Angle(degrees: currentDegrees + deltaDegrees),
                color: asset.color))
            currentDegrees += deltaDegrees
        }
        self.slices = slices
    }
    
    var body: some View {
        ZStack {
            ForEach(slices) {
                PieChartSlice(slice: $0)
            }
        }
        .padding(EdgeInsets(top: 42, leading: 42, bottom: 42, trailing: 42))
        .frame(width: 320, height: 320)
    }
}

struct AssetAllocationView: View {
    
    @ObservedObject var controller: AssetAllocationController
    
    init(controller: AssetAllocationController) {
        self.controller = controller
    }
    
    var currencyPicker: some View {
        Picker("Currency", selection: $controller.selectedCurrency) {
            ForEach(Currency.allCases) { currency in
                Text(currency.symbol)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                currencyPicker
                    .padding(-8)
//                    .border(.red)
                HStack {
                    Text("Balance \(controller.selectedCurrency.symbol)")
                    Spacer()
                    Text(controller.balance)
                }
                .padding(.horizontal, 16)
                
                PieChartOld(allocations: controller.allocations)
                    .padding(-16)
//                    .border(.red)
                
                List {
                    ForEach(controller.allocations) { item in
                        HStack {
                            Rectangle()
                                .foregroundColor(item.color)
                                .frame(width: 16, height: 16)
                            Text(String(format: "%.2f%%", (item.normalizedValue * 100)))
                                .font(.caption2)
                            Text(item.name)
                                .font(.caption)
//                            Text(item.ticker)
//                                .font(.caption2)
                            Spacer()
                            Text(item.priceValue)
                        }
                    }
                }
//                .border(.red)
            }
            .navigationTitle(controller.title)
        }
    }
}

#Preview {
//    AssetAllocationView()
    AssetAllocationView(controller: AssetAllocationController(type: .crypto))
}

