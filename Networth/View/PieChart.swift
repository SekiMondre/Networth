import SwiftUI
import Charts

struct PetData {
    let year: Int
    let population: Double
    
}

//struct Allocation: Hashable, Identifiable {
//    let ticker: String
//    let name: String
//    let priceValue: String
//    let value: Double
//    let normalizedValue: Double
//    let currency: Currency
//    let color: Color
//}

//struct DataItem

struct PieChart: View {
    
    var data: [(tag: String, amount: Double)] {
        [
            (tag: "BTC", amount: 1000),
            (tag: "ETH", amount: 500)
        ]
    }
    
    var body: some View {
        Chart(data, id: \.tag) { item in
            SectorMark(angle: .value("Asdsds", item.amount))
                .foregroundStyle(by: .value("effefe", item.tag))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    Text("\(item.amount)")
                        .font(.headline)
                }
//                .symbol(.diamond)
//                .annotation {
//                    Text(item.tag)
//                }
        }
    }
}

struct PieChartExampleView: View {
    
    let catData = [PetData(year: 2000, population: 6.8),
                   PetData(year: 2010, population: 8.2),
                   PetData(year: 2015, population: 12.9),
                   PetData(year: 2022, population: 15.2)]
    let dogData = [PetData(year: 2000, population: 5),
                   PetData(year: 2010, population: 5.3),
                   PetData(year: 2015, population: 7.9),
                   PetData(year: 2022, population: 10.6)]
    
    var catTotal: Double {
        catData.reduce(0) { $0 + $1.population }
    }

    var dogTotal: Double {
        dogData.reduce(0) { $0 + $1.population }
    }

    var data: [(type: String, amount: Double)] {
        [(type: "cat", amount: catTotal),
         (type: "dog", amount: dogTotal)
        ]
    }

    var maxPet: String? {
        data.max { $0.amount < $1.amount }?.type
    }

    var body: some View {
        Chart(data, id: \.type) { dataItem in
            SectorMark(angle: .value(dataItem.type, dataItem.amount),
                       innerRadius: .ratio(0.4),
                       angularInset: 1.5)
                .cornerRadius(5)
                .opacity(dataItem.type == maxPet ? 1 : 0.5)
                .foregroundStyle(by: .value("Type", dataItem.type))
//                .foregroundStyle(.green)
        }
        .frame(height: 200)
    }
}

#Preview {
//    PieChartExampleView()
    PieChart()
}
