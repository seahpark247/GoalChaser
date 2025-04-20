//
//  ContentView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//
// 유저 디폴트로 저장하는거 구현
// 다른 페이지도 만들기
// 예상 작업시간 ... 6시간 to finish it

import SwiftUI

//@Observable
//class Expenses {
//    var items = [ExpenseItem]() {
//        didSet {
//            if let encoded = try? JSONEncoder().encode(items) {
//                UserDefaults.standard.set(encoded, forKey: "Items")
//            }
//        }
//    }
//    
//    init() {
//        if let savedItems = UserDefaults.standard.data(forKey: "Items") {
//            if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
//                items = decodedItems
//                return // exit initializer
//            }
//        }
//        
//        items = []
//    }
//}

struct GoalItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var days: Int = 30
    var color = "Blue"
    var buttonShape = "Square"
    var isDone: Bool = false
}

@Observable
class Goals {
    var items = [GoalItem]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }
    
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items") {
            if let decodedItems = try? JSONDecoder().decode([GoalItem].self, from: savedItems) {
                items = decodedItems
                return 
            }
        }
        
        items = []
    }
}

struct ContentView: View {
    @State private var goalTitle: String = "Study 1 hour"
    @State private var selectedTab = 0
    @State private var tabTitles: [String] = ["Study 1hour", "Make a bed", "Feed dog", "Wake up at 6am", "Go to gym"]
    @State private var tabContents: [Int] = [20, 30, 16, 13, 7]
    let columns = [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(tabTitles.indices, id: \.self) { index in
                        Text("\(index + 1)").tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button(action: {
//                    guard 00 시 지나면 다시 클릭 가능
                    guard tabContents[selectedTab] > 0 else { return }
                    
                    // 햅틱 피드백 생성
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()

                    tabContents[selectedTab] -= 1
                }) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<tabContents[selectedTab], id: \.self) { index in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 50)
                                .cornerRadius(5)
                        }
                    }
                }
            }.navigationTitle(tabTitles[selectedTab])
            
            Spacer()
            
            HStack {
                Spacer()
                NavigationLink(destination: RewardsView()) {
                    Image(systemName: "trophy").imageScale(.large)
                                    }
                Spacer()
                NavigationLink(destination: EditorView()) {
                    Image(systemName: "square.and.pencil").imageScale(.large)
                }
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
