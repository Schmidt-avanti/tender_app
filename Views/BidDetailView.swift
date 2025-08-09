import SwiftUI

/// Provides a detailed view for a single bid.  Users can update the
/// bid's status, manage the list of tasks, mark tasks as complete,
/// and add comments.  All changes are persisted via the
/// `BidManager`.
struct BidDetailView: View {
    @EnvironmentObject private var bidManager: BidManager
    @EnvironmentObject private var favs: FavoritesManager
    @State private var bid: Bid
    @State private var newTaskTitle: String = ""
    @State private var newTaskDescription: String = ""
    @State private var newCommentText: String = ""
    @State private var showAddTask: Bool = false
    @State private var showAddComment: Bool = false

    init(bid: Bid) {
        // copy for editing; will sync back via update()
        _bid = State(initialValue: bid)
    }

    var body: some View {
        Form {
            Section(header: Text("Ausschreibung")) {
                Text(bid.tender.title)
                    .font(.headline)
                if let buyer = bid.tender.buyer {
                    Text("Auftraggeber: \(buyer)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("Status")) {
                Picker("Status", selection: $bid.status) {
                    ForEach(BidStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(header: Text("Aufgaben")) {
                ForEach($bid.tasks) { $task in
                    HStack {
                        Button(action: {
                            task.isCompleted.toggle()
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            Text(task.title)
                            if let desc = task.description {
                                Text(desc)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    bid.tasks.remove(atOffsets: offsets)
                }
                Button(action: { showAddTask = true }) {
                    Label("Aufgabe hinzufügen", systemImage: "plus")
                }
            }
            Section(header: Text("Kommentare")) {
                ForEach(bid.comments) { comment in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(comment.author)
                                .font(.subheadline)
                                .bold()
                            Spacer()
                            Text(comment.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(comment.message)
                    }
                }
                Button(action: { showAddComment = true }) {
                    Label("Kommentar hinzufügen", systemImage: "plus.bubble")
                }
            }
        }
        .navigationTitle("Bid Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // persist changes when leaving the screen
            bidManager.update(bid: bid)
        }
        .sheet(isPresented: $showAddTask) {
            NavigationStack {
                Form {
                    Section(header: Text("Titel")) {
                        TextField("Task", text: $newTaskTitle)
                    }
                    Section(header: Text("Beschreibung")) {
                        TextEditor(text: $newTaskDescription)
                            .frame(height: 100)
                    }
                }
                .navigationTitle("Neue Aufgabe")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            let task = BidTask(title: newTaskTitle, isCompleted: false, description: newTaskDescription.isEmpty ? nil : newTaskDescription)
                            bid.tasks.append(task)
                            newTaskTitle = ""
                            newTaskDescription = ""
                            showAddTask = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            newTaskTitle = ""
                            newTaskDescription = ""
                            showAddTask = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddComment) {
            NavigationStack {
                Form {
                    Section(header: Text("Nachricht")) {
                        TextEditor(text: $newCommentText)
                            .frame(height: 150)
                    }
                }
                .navigationTitle("Neuer Kommentar")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            let comment = BidComment(author: "Ich", message: newCommentText)
                            bid.comments.append(comment)
                            newCommentText = ""
                            showAddComment = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            newCommentText = ""
                            showAddComment = false
                        }
                    }
                }
            }
        }
    }
}

struct BidDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let tender = Tender(id: "1", source: "demo", title: "Sample", buyer: "City", cpv: ["123456"], country: "DE", city: "Berlin", deadline: Date(), valueEstimate: 1000, url: nil)
        let bid = Bid(tender: tender)
        return NavigationStack {
            BidDetailView(bid: bid)
        }
        .environmentObject(BidManager.shared)
        .environmentObject(FavoritesManager.shared)
    }
}