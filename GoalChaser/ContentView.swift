//
//  ContentView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//
// TODO: days0 됬을 때 나는 에러 수정

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
                        
                        Text("목표를 추가해주세요")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("편집 버튼을 눌러 새로운 목표를 추가하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 50)
                } else {
                    // 안전한 탭 인덱스 계산 (범위를 벗어나지 않도록)
                    let safeTabIndex = min(selectedTab, activeGoals.count - 1)
                    
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(activeGoals.indices, id: \.self) { index in
                            Text(activeGoals[index].title).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .id(activeGoals.count) // 목표 개수가 변경될 때 Picker 새로고침
                    
                    // 목표 정보와 버튼 표시
                    let goalToShow = activeGoals[safeTabIndex]
                    let isTappable = canTapToday(lastTappedDate: goalToShow.lastTappedDate)
                    
                    let columns = [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))]
                    
                    Button(action: {
                        guard isTappable else { return }
                        
                        // 햅틱 피드백 생성
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()

                        // 원본 배열에서 항목 찾아 업데이트
                        if let originalIndex = goals.items.firstIndex(where: { $0.id == goalToShow.id }) {
                            goals.items[originalIndex].lastTappedDate = Date()
                            goals.items[originalIndex].days -= 1
                            
                            // 모든 목표가 완료되면 selectedTab 재설정 및 알림 표시
                            if goals.items[originalIndex].days == 0 {
                                completedGoalTitle = goals.items[originalIndex].title
                                showCompletionAlert = true
                                
                                DispatchQueue.main.async {
                                    // 이미 여기서 목표가 완료되어 activeGoals 배열에서 제거됨
                                    // 아주 안전하게 선택된 탭을 재설정
                                    if activeGoals.isEmpty {
                                        selectedTab = 0
                                    } else {
                                        selectedTab = min(selectedTab, activeGoals.count - 1)
                                    }
                                }
                            }
                        }
                    }) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(0..<goalToShow.days, id: \.self) { _ in
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
                        Text("\(goalToShow.days)일 남았습니다")
                            .padding()
                    } else {
                        Text("\(goalToShow.days)일 남았습니다").padding(.top)
                        Text("오늘은 이미 완료했습니다. 내일 다시 도전하세요!")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            .navigationTitle(activeGoals.isEmpty ? "Goal Chaser" :
                           (activeGoals.indices.contains(selectedTab) ? activeGoals[selectedTab].title : "Goal Chaser"))
            .alert(isPresented: $showCompletionAlert) {
                Alert(
                    title: Text("🎉 목표 달성 축하합니다! 🎉"),
                    message: Text("\(completedGoalTitle) 목표를 성공적으로 완료했어요!\n당신의 노력과 끈기에 박수를 보냅니다."),
                    dismissButton: .default(Text("확인"))
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
}

#Preview {
    ContentView()
}
