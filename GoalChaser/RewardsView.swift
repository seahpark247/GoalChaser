//
//  RewardsView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//

import SwiftUI

struct RewardsView: View {
    @State var goals: Goals
    @State private var showConfetti = false
    
    var completedGoals: [GoalItem] {
        goals.items.filter { $0.days == 0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if completedGoals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Completed goals will appear here.")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Achieve your goals to earn trophies!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 50)
                } else {
                    List {
                        Section(header: Text("Completed Goals").font(.headline)) {
                            ForEach(completedGoals) { goal in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(goal.title)
                                        .strikethrough() // 취소선 추가
                                    
                                    Spacer()
                                    
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        Section(header: Text("Achievement Statistics").font(.headline)) {
                            HStack {
                                Text("Completed Goals")
                                Spacer()
                                Text("\(completedGoals.count)")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Achievements")
            .onAppear {
                // 완료된 목표가 있으면 축하 효과 표시
                if !completedGoals.isEmpty {
                    showConfetti = true
                    
                    // 3초 후에 효과 끄기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showConfetti = false
                    }
                }
            }
            .overlay(
                // 간단한 축하 효과 (실제 앱에서는 더 멋진 애니메이션을 구현할 수 있습니다)
                Group {
                    if showConfetti {
                        ZStack {
                            ForEach(0..<20) { i in
                                Circle()
                                    .fill(Color.random)
                                    .frame(width: CGFloat.random(in: 5...15))
                                    .position(
                                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                                    )
                                    .animation(
                                        Animation.linear(duration: 2)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double.random(in: 0...0.5)),
                                        value: showConfetti
                                    )
                            }
                        }
                        .transition(.opacity)
                    }
                }
            )
        }
    }
    
}

// 랜덤 색상 생성을 위한 확장
extension Color {
    static var random: Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors.randomElement() ?? .blue
    }
}

// Preview
#Preview {
    // 미리보기용 데이터 생성
    let previewGoals = Goals()
    previewGoals.items = [
        GoalItem(title: "Morning Exercise", days: 0, isDone: true),
        GoalItem(title: "Study English", days: 0, isDone: true),
        GoalItem(title: "Reading", days: 5)
    ]
    
    return RewardsView(goals: previewGoals)
}
