//
//  RewardsView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//

import SwiftUI

// 응원 메시지를 위한 데이터 구조
struct RewardMessages: Codable {
    let messages: [String]
}

struct RewardsView: View {
    @State var goals: Goals
    @State private var showConfetti = false
    @State private var showRewardAlert = false
    @State private var rewardMessage = ""
    
    // 앱 시작 시 JSON에서 메시지 로드
    @State private var rewardMessages: [String] = []
    
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
                        Section(header: Text("Achievement Statistics").font(.headline)) {
                            HStack {
                                Text("Completed Goals")
                                Spacer()
                                Text("\(completedGoals.count)")
                                    .fontWeight(.bold)
                            }
                        }

                        Section(header: Text("Completed Goals").font(.headline)) {
                            ForEach(completedGoals) { goal in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(goal.title)
                                        .strikethrough()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                }
                                .padding(.vertical, 8)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        // 목표 삭제 함수 호출
                                        deleteGoal(goal)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Secret Reward") {
                        // 랜덤 응원 메시지 선택
                        if !rewardMessages.isEmpty {
                            rewardMessage = rewardMessages.randomElement() ?? "You're amazing!"
                        } else {
                            rewardMessage = "You're amazing!" // 기본 메시지
                        }
                        playRewardHaptic()
                        showRewardAlert = true
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                }
            }
            .alert(isPresented: $showRewardAlert) {
                Alert(
                    title: Text("✨ Look at YOU!!! ✨"),
                    message: Text(rewardMessage),
                    dismissButton: .default(Text("Thank you!"))
                )
            }
            .onAppear {
                // 메시지 로드
                loadEncouragementMessages()
                
                if !completedGoals.isEmpty {
                    // Show confetti immediately with no delay
                    showConfetti = true
                    
                    // Hide confetti after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showConfetti = false
                    }
                }
            }
            .overlay(
                ZStack {
                    if showConfetti && !completedGoals.isEmpty {
                        ConfettiView()
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )
        }
    }
    
    // 완료된 목표 삭제 함수
    private func deleteGoal(_ goal: GoalItem) {
        // 항목 인덱스 찾기
        if let index = goals.items.firstIndex(where: { $0.id == goal.id }) {
            // 목록에서 항목 삭제
            goals.items.remove(at: index)
            
            // UserDefaults에 업데이트된 데이터 저장
            saveGoalsToUserDefaults()
        }
    }
    
    // UserDefaults에 목표 데이터 저장
    private func saveGoalsToUserDefaults() {
        do {
            // GoalItem을 Data로 인코딩
            let encoder = JSONEncoder()
            let data = try encoder.encode(goals.items)
            
            // UserDefaults에 저장
            UserDefaults.standard.set(data, forKey: "savedGoals")
        } catch {
            print("목표 저장 오류: \(error.localizedDescription)")
        }
    }
    
    // JSON 파일에서 응원 메시지 로드하는 함수
    private func loadEncouragementMessages() {
        guard let url = Bundle.main.url(forResource: "reward_messages", withExtension: "json") else {
            print("JSON 파일을 찾을 수 없습니다.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(RewardMessages.self, from: data)
            self.rewardMessages = jsonData.messages
        } catch {
            print("JSON 파일 로드 오류: \(error.localizedDescription)")
        }
    }
    
    func playRewardHaptic() {
        // 성공 알림 진동
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // "딴딴" 패턴으로 2번 진동 (강, 약)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred() // 강
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let light = UIImpactFeedbackGenerator(style: .light)
                light.impactOccurred() // 약
            }
        }
    }
}

// Improved confetti animation component
struct ConfettiView: View {
    let confettiCount = 12 // Slightly increased for bigger circles
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<confettiCount, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
            }
        }
    }
}

// Individual confetti piece with natural falling animation
struct ConfettiPiece: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    
    @State private var location = CGPoint(x: 0, y: 0)
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 20...35), height: CGFloat.random(in: 20...35)) // Larger circles
            .scaleEffect(scale)
            .position(location)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                // Random starting position at the top
                let randomX = CGFloat.random(in: 0...width)
                location = CGPoint(x: randomX, y: -20)
                
                // Random horizontal movement
                let randomEndX = randomX + CGFloat.random(in: -50...50)
                let endLocation = CGPoint(x: randomEndX, y: height + 20)
                
                // Animation
                withAnimation(.easeOut(duration: Double.random(in: 0.8...1.2))) { // Faster animation
                    opacity = 1
                    scale = CGFloat.random(in: 0.7...1.0)
                }
                
                // Falling animation
                withAnimation(
                    Animation
                        .easeIn(duration: Double.random(in: 0.6...1.2)) // Faster falling
                        .delay(Double.random(in: 0...0.2)) // Shorter delay
                ) {
                    location = endLocation
                }
                
                // Rotation animation
                withAnimation(
                    Animation
                        .linear(duration: Double.random(in: 0.6...1.0)) // Faster rotation
                        .delay(Double.random(in: 0...0.2)) // Shorter delay
                        .repeatCount(3, autoreverses: false) // Add rotation repetition
                ) {
                    rotation = Double.random(in: 360...720) // More rotation
                }
                
                // Fade out at the end
                withAnimation(
                    Animation
                        .easeOut(duration: 0.3)
                        .delay(1.0) // Shorter delay before fade out
                ) {
                    opacity = 0
                }
            }
    }
}

extension Color {
    static var random: Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors.randomElement() ?? .blue
    }
}

// Preview
#Preview {
    // Sample data for preview
    let previewGoals = Goals()
    previewGoals.items = [
        GoalItem(title: "Morning Exercise", days: 0, isDone: true),
        GoalItem(title: "Study English", days: 0, isDone: true),
        GoalItem(title: "Reading", days: 5)
    ]
    
    return RewardsView(goals: previewGoals)
}
