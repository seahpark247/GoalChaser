//
//  EditorView.swift
//  GoalChaser
//
//  Created by Seah Park on 4/19/25.
//

import SwiftUI

struct EditorView: View {
    @State private var goals: [String] = []
    @State private var inputGoal: String = ""
    @State private var showAlert = false
    
    var inputDisabled: Bool {
        // limit 5
        goals.count > 4
    }
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    TextField("Input Your Goal", text: $inputGoal).disabled(inputDisabled)
                    Button(action: {addGoal()}) {
                        Image(systemName: "plus").foregroundColor(!inputDisabled ? .blue : .gray)
                    }
                }.padding()
                
                if !goals.isEmpty {
                    Section {
                        ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                            HStack {
                                Image(systemName: "\(index + 1).circle")
                                Text(goal)
                            }
                        }.onDelete(perform: removeGoal)
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
        
        goals.append(inputGoal)
        inputGoal = ""
    }
    
    func removeGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
}

#Preview {
    EditorView()
}
