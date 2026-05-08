import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            RoomView()
                .tabItem { Label("部屋", systemImage: "house.fill") }
            FurnitureView()
                .tabItem { Label("家具", systemImage: "shippingbox.fill") }
            CollectionView()
                .tabItem { Label("図鑑", systemImage: "book.fill") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SightingRecord.self, inMemory: true)
}
