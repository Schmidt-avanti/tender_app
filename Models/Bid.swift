import Foundation

/// Represents a single step or action required to prepare a bid
/// submission.  Tasks can be checked off when complete and may
/// include an optional description.
struct BidTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var description: String?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, description: String? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.description = description
    }
}

/// Represents a comment left by a team member on a bid.  Stores
/// metadata such as author and timestamp for audit purposes.  In a
/// production environment this would likely reside on a backend.
struct BidComment: Identifiable, Codable, Hashable {
    let id: UUID
    var author: String
    var message: String
    var createdAt: Date

    init(id: UUID = UUID(), author: String, message: String, createdAt: Date = Date()) {
        self.id = id
        self.author = author
        self.message = message
        self.createdAt = createdAt
    }
}

/// Defines the possible states of a bid within the workflow.  A bid
/// typically moves from "evaluating" to either "submitted" or
/// "declined".
enum BidStatus: String, Codable, CaseIterable {
    case evaluating = "Evaluierung"
    case preparing = "In Vorbereitung"
    case submitted = "Eingereicht"
    case declined = "Abgelehnt"
}

/// Represents a bid record tied to a tender.  Includes status,
/// tasks and comments.  Allows multiple team members to collaborate
/// on preparing and submitting the bid.
struct Bid: Identifiable, Codable, Hashable {
    let id: UUID
    var tender: Tender
    var status: BidStatus
    var tasks: [BidTask]
    var comments: [BidComment]
    var createdAt: Date

    init(id: UUID = UUID(), tender: Tender, status: BidStatus = .evaluating, tasks: [BidTask] = [], comments: [BidComment] = [], createdAt: Date = Date()) {
        self.id = id
        self.tender = tender
        self.status = status
        self.tasks = tasks
        self.comments = comments
        self.createdAt = createdAt
    }
}