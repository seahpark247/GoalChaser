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
    
    var inputDisabled: Bool {
        // limit 5
        goals.items.count > 4
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Input Your Goal", text: $inputGoal).disabled(inputDisabled)
                    
                    // Day picker
                    ZStack {
                        Picker("Days you want to achieve", selection: $selectedDays) {
                            ForEach(2...31, id: \.self) { day in
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
                
                if !goals.items.isEmpty {
                    Section {
                        ForEach(Array(goals.items.enumerated()), id: \.element.id) { index, goal in
                            HStack {
                                Image(systemName: "\(index + 1).circle")
                                Text(goal.title)
                                Spacer()
                                Text("Day \(goal.days)")
                            }
                        }
                        .onDelete(perform: removeGoal)
                    }
                }
            }
            .navigationTitle("Editor")
            .alert(inputDisabled ? "You've reached 5 goals limit." : "Input your goal!", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
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
        goals.items.remove(atOffsets: offsets)
    }
}

#Preview {
    EditorView(goals: Goals())
}
