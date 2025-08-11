import Foundation
import SwiftUI

@MainActor
final class DetailViewModel: ObservableObject {
    @Published var notice: Notice
    init(notice: Notice) { self.notice = notice }
    var htmlURL: URL { TedEndpoints.htmlLink(publicationNumber: notice.publicationNumber) }
    var pdfURL: URL { TedEndpoints.pdfLink(publicationNumber: notice.publicationNumber) }
}
