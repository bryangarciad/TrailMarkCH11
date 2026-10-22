import Foundation
import Combine
import Observation
import AVFoundation // Media Tool

@MainActor
@Observable
public final class MediaStore {
    public private(set) var memos: [MediaMemo] = [] // In Memory reference For UI
    
    private let fileManager = FileManager.default
    private let indexFileName = "memos.json" // index
    
    public init() {
        loadIndex()
    }
    
    public var mediaDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0] // username/.trailmark
        let dir = base.appendingPathComponent("Media", isDirectory: true)
        // username/.trailmark/Media/
        if  !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }
    
    // This is for the index; mediaDir + index
    private var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }
    
    // This is for the media memo files; mediaDir + memo file name
    public func url(for memo: MediaMemo) -> URL {
        mediaDirectory.appendingPathComponent(memo.fileName)
    }
    
    // MARK: - Saving
    @discardableResult
    public func add(
        type: MemoType,
        movingFileFrom sourceURL: URL,
        duration: TimeInterval,
        title: String = ""
    ) throws -> MediaMemo {
        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ?
            (type == .audio ? "m4a" : "mov") :
            sourceURL.pathExtension
        
        let fileName = "\(id.uuidString).\(ext)"
        let destination = mediaDirectory.appendingPathComponent(fileName)
        
        // This step is going to prevent collisions due to duplicate files
        // Which is anyways very unlikely due to UUID
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.moveItem(at: sourceURL, to: destination)

        var memo = MediaMemo(
            id: id,
            type: type,
            fileName: fileName,
            duration: duration,
            title: title
        )
        
        memos.insert(memo, at: 0) // This will ensure the memos to always be sorted descending
        persistMemoToIndex()
        return memo
    }
    
    public func delete(_ memo: MediaMemo)    {
        let fileURL = url(for: memo)
        try? fileManager.removeItem(at: fileURL) // nil
        memos.removeAll { $0.id == memo.id }
        persistMemoToIndex()
    }
    
    // MARK: - Index Persistance
    
    // When you reopen the app we want to reconciliate the in memory
    // memos arr with the index
    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoded = (try? JSONDecoder().decode([MediaMemo].self, from: data)) ?? []

        memos = decoded.sorted { $0.createdAt > $1.createdAt } // This will re add the memos in desc order
    }
    
    private func persistMemoToIndex() {
        guard let data = try? JSONEncoder().encode(memos) else { return }
        try? data.write(to: indexURL, options: .atomic)
        
    }
    
}
