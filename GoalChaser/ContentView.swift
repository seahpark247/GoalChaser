//
//  ContentView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//
// TODO: 목표 0일이면 메인화면에서 지우기, 에디터뷰에서도 지우기.

import SwiftUI

struct GoalItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var days: Int = 30
    var color = "Blue"
    var buttonShape = "Square"
    var isDone: Bool = false
    var lastTappedDate: Date? = nil // 마지막으로 탭한 날짜 저장
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
    @State var goals = Goals()
    @State private var selectedTab = 0
    
    // 오늘 탭 가능한지 확인하는 함수
    func canTapToday(lastTappedDate: Date?) -> Bool {
        guard let lastTapped = lastTappedDate else {
            // 한 번도 탭한 적이 없으면 탭 가능
            return true
        }
        
        // 현재 날짜의 Calendar 컴포넌트 가져오기
        let calendar = Calendar.current
        let now = Date()
        
        // 마지막 탭한 날짜와 현재 날짜가 다른 날인지 확인
        return !calendar.isDate(lastTapped, inSameDayAs: now)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if goals.items.isEmpty {
                    Text("Please add a goal")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(goals.items.indices, id: \.self) { index in
                            Text(goals.items[index].title).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab < goals.items.count {
                        let columns = [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))]
                        
                        let isTappable = canTapToday(lastTappedDate: goals.items[selectedTab].lastTappedDate)
                        
                        Button(action: {
                            guard goals.items[selectedTab].days > 0 else { return }
                            guard isTappable else { return }
                            
                            // 햅틱 피드백 생성
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()

                            // 마지막 탭 날짜 업데이트
                            goals.items[selectedTab].lastTappedDate = Date()
                            goals.items[selectedTab].days -= 1
                        }) {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(0..<goals.items[selectedTab].days, id: \.self) { index in
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: 50)
                                        .cornerRadius(5)
                                }
                            }
                            .opacity(isTappable ? 1.0 : 0.5)
                        }
                        .disabled(!isTappable)
                        
                        if isTappable {
                            Text("\(goals.items[selectedTab].days) days left")
                                .padding()
                        } else {
                            Text("\(goals.items[selectedTab].days) days left").padding(.top)
                            Text("You've already completed today. Try again tomorrow!")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle(selectedTab < goals.items.count ? goals.items[selectedTab].title : "Goal Chaser")
            
            Spacer()
            
            HStack {
                Spacer()
                NavigationLink(destination: RewardsView(goals: goals)) {
                    Image(systemName: "trophy").imageScale(.large)
                }
                Spacer()
                NavigationLink(destination: EditorView(goals: goals)) {
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
