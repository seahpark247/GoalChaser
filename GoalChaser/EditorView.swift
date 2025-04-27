//
//  EditorView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//

import SwiftUI

struct EditorView: View {
    @Bindable var goals: Goals
    @State private var inputGoal: String = ""
    @State private var showAlert = false
    @State private var selectedDays: Int = 7 // Default value of 7
    
    // 완료되지 않은 목표만 필터링하는 계산 속성
    var activeGoals: [GoalItem] {
        goals.items.filter { $0.days > 0 }
    }
    
    var inputDisabled: Bool {
        // limit 5
        activeGoals.count > 4
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("notepadBackground")
                    .resizable()
                    .overlay(Color.black.opacity(0.08))
                    .edgesIgnoringSafeArea(.all)

                List {
                    Section {
                        TextField("Input Your Goal", text: $inputGoal).disabled(inputDisabled)
                        
                        // Day picker
                        ZStack {
                            Picker("Days you want to achieve", selection: $selectedDays) {
                                ForEach(1...31, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .disabled(inputDisabled)
                            .opacity(inputDisabled ? 0.5 : 1)
                            
                            // inputDisabled일 때만 나타나는 투명한 오버레이
                            if inputDisabled {
                                Rectangle()
                                    .fill(Color.clear)  // 투명
                                    .contentShape(Rectangle())  // 전체 영역이 탭 가능하도록
                                    .onTapGesture {} // 빈 탭 제스처로 기본 동작 차단
                            }
                        }
                        
                        
                        Button(action: {addGoal()}) {
                            HStack() {
                                Spacer()
                                Image(systemName: "plus").foregroundColor(!inputDisabled ? .blue : .gray)
                                Spacer()
                            }
                        }
                    }
                    
                    if !activeGoals.isEmpty {
                        Section {
                            ForEach(activeGoals) { goal in
                                HStack {
                                    // 인덱스 대신 실제 활성 목표의 인덱스 계산
                                    if let index = activeGoals.firstIndex(where: { $0.id == goal.id }) {
                                        Image(systemName: "\(index + 1).circle")
                                        Text(goal.title)
                                        Spacer()
                                        Text("Day \(goal.days)")
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        if let index = goals.items.firstIndex(where: { $0.id == goal.id }) {
                                            goals.items.remove(at: index)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Editor")
                .alert(inputDisabled ? "You've reached 5 goals limit." : "Input your goal!", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                }
            
            }
        }
    }
    
    func addGoal() {
        guard !inputDisabled else {
            return showAlert = true
        }
        guard !inputGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert = true
            inputGoal = ""
            return
        }
        
        goals.items.append(GoalItem(title: inputGoal, days: selectedDays))
        inputGoal = ""
        selectedDays = 7
    }
    
    func removeGoal(at offsets: IndexSet) {
        // 활성 목표의 인덱스를 원본 배열의 인덱스로 변환
        let originalIndices = offsets.map { activeGoals[$0].id }.compactMap { id in
            goals.items.firstIndex { $0.id == id }
        }
        
        // 원본 배열에서 해당 항목 삭제
        for index in originalIndices.sorted(by: >) {
            goals.items.remove(at: index)
        }
    }
}

#Preview {
    EditorView(goals: Goals())
}
