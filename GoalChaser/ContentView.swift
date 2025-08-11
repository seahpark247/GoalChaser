//
//  ContentView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//
// TODO: daily acheivements(miss/acheive) / calender style
// test2

import SwiftUI

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct GoalItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var days: Int = 31
    var color = "blue"
    var isDone: Bool = false
    var lastTappedDate: Date? = nil // 마지막으로 탭한 날짜 저장
    
    enum CodingKeys: String, CodingKey {
        case id, title, days, color, isDone, lastTappedDate
    }
    
    // Color는 Codable이 아니므로 계산 프로퍼티로 제공
    var uiColor: Color {
        switch color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .blue
        }
    }
    
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
    @State private var showCompletionAlert = false
    @State private var completedGoalTitle = ""
    
    // 아직 완료되지 않은 목표만 필터링
    var activeGoals: [GoalItem] {
        goals.items.filter { $0.days > 0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if activeGoals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Please add a goal")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Tap the edit button down below to create a new goal")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 50)
                } else {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(Array(activeGoals.enumerated()), id: \.offset) { index, goal in
                            Text(goal.title).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .id(activeGoals.count) // 목표 개수가 변경될 때 Picker 새로고침
                    
                    // 목표 정보와 버튼 표시
                    if let goalToShow = activeGoals[safe: selectedTab] {
                        let isTappable = canTapToday(lastTappedDate: goalToShow.lastTappedDate)
                        
                        let columns = [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))]
                        
                        Button(action: {
                            guard isTappable else { return }

                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()

                            if let originalIndex = goals.items.firstIndex(where: { $0.id == goalToShow.id }) {
                                
                                goals.items[originalIndex].lastTappedDate = Date()
                                goals.items[originalIndex].days -= 1

                                if goals.items[originalIndex].days == 0 {
                                    completedGoalTitle = goals.items[originalIndex].title
                                    showCompletionAlert = true
                                    
                                    // 특별한 진동 패턴 실행 - "딴딴 딴 딴딴" 패턴으로 5번
                                    playCompletionHaptic()

                                    // 목표 사라지기 전에 탭 인덱스 조정
                                    let nextCount = activeGoals.count - 1
                                    selectedTab = max(0, min(selectedTab, nextCount - 1))
                                }
                            }
                        }) {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(0..<goalToShow.days, id: \.self) { _ in
                                    Rectangle()
                                        .fill(goalToShow.uiColor)
                                        .frame(height: 50)
                                        .cornerRadius(5)
                                }
                            }
                            .opacity(isTappable ? 1.0 : 0.5)
                        }
                        .disabled(!isTappable)
                        
                        if isTappable {
                            Text("\(goalToShow.days) days left").padding()
                        } else {
                            Text("\(goalToShow.days) days left").padding(.top)
                            Text("Good job! Come back tomorrow!")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    } else {
                        Text("Unable to load goal.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            .navigationTitle(activeGoals.isEmpty ? "Goal Chaser" :
                (activeGoals.indices.contains(selectedTab) ? activeGoals[selectedTab].title : "Goal Chaser"))
            .alert(isPresented: $showCompletionAlert) {
                Alert(
                    title: Text("🎉 Congratulations on Achieving Your Goal! 🎉"),
                    message: Text("You successfully completed the goal: \(completedGoalTitle)\nYour effort and persistence are truly impressive."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
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
        .onChange(of: activeGoals.count) { oldCount, newCount in
            // 활성 목표 개수가 변경될 때 selectedTab 조정
            if newCount == 0 {
                selectedTab = 0
            } else if selectedTab >= newCount {
                selectedTab = max(0, newCount - 1)
            }
        }
    }
    
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
    
    // "딴딴 딴 딴딴" 패턴으로 진동 효과 재생
    func playCompletionHaptic() {
        // 성공 알림 진동
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // "딴딴 딴 딴딴" 패턴으로 5번 진동 (강, 강, 약, 강, 강)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred() // 강
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heavy.impactOccurred() // 강
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let light = UIImpactFeedbackGenerator(style: .light)
                    light.impactOccurred() // 약
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        heavy.impactOccurred() // 강
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            heavy.impactOccurred() // 강
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
