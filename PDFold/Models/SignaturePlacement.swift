import Foundation

struct SignaturePlacement: Codable, Identifiable {
    var id: UUID = UUID()
    var pageRefId: UUID
    var imageData: Data
    var rect: CGRect
    var signerName: String?
    var signedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, pageRefId, imageData, rect, signerName, signedAt
    }

    init(id: UUID = UUID(), pageRefId: UUID, imageData: Data, rect: CGRect, signerName: String? = nil, signedAt: Date? = nil) {
        self.id = id
        self.pageRefId = pageRefId
        self.imageData = imageData
        self.rect = rect
        self.signerName = signerName
        self.signedAt = signedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        pageRefId = try c.decode(UUID.self, forKey: .pageRefId)
        imageData = try c.decode(Data.self, forKey: .imageData)
        let rd = try c.decode([String: Double].self, forKey: .rect)
        rect = CGRect(x: rd["x"] ?? 0, y: rd["y"] ?? 0, width: rd["width"] ?? 0, height: rd["height"] ?? 0)
        signerName = try c.decodeIfPresent(String.self, forKey: .signerName)
        signedAt = try c.decodeIfPresent(Date.self, forKey: .signedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(pageRefId, forKey: .pageRefId)
        try c.encode(imageData, forKey: .imageData)
        try c.encode(["x": rect.origin.x, "y": rect.origin.y, "width": rect.size.width, "height": rect.size.height], forKey: .rect)
        try c.encodeIfPresent(signerName, forKey: .signerName)
        try c.encodeIfPresent(signedAt, forKey: .signedAt)
    }
}
