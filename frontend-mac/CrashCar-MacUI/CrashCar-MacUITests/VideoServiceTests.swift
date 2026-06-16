//
//  VideoServiceTests.swift
//  CrashCar-MacUITests
//
//  Sesión 6 — Tests de preparación de vídeos. No dependen de un recurso del
//  bundle (el plan usaba `test_clip.mp4`); en su lugar generan un fichero
//  temporal, para que el test sea autocontenido y no requiera assets.
//

import XCTest
@testable import CrashCar_MacUI

@MainActor
final class VideoServiceTests: XCTestCase {

    private var tempDirs: [URL] = []

    override func tearDown() {
        for dir in tempDirs {
            try? FileManager.default.removeItem(at: dir)
        }
        tempDirs.removeAll()
        super.tearDown()
    }

    func testPreparedVideoIsCopiedToWorkspace() async throws {
        let workspace = makeTempDir()
        let service = VideoService(workspaceDir: workspace)
        let source = makeDummyVideo()

        let result = try await service.prepareForFastAPI(url: source)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result))
        XCTAssertTrue(result.hasPrefix(workspace.path))
        XCTAssertTrue(result.hasSuffix(".mp4"))
    }

    func testWorkspaceDirCreatedIfMissing() async throws {
        let parent = makeTempDir()
        let newDir = parent.appendingPathComponent("newuploads", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: newDir.path))

        let service = VideoService(workspaceDir: newDir)
        try await service.ensureWorkspaceDirExists()

        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path))
    }

    func testPreparedCopyPreservesContents() async throws {
        let workspace = makeTempDir()
        let service = VideoService(workspaceDir: workspace)
        let source = makeDummyVideo(contents: "crash-car-bytes")

        let result = try await service.prepareForFastAPI(url: source)

        let copied = try String(contentsOfFile: result, encoding: .utf8)
        XCTAssertEqual(copied, "crash-car-bytes")
    }

    // MARK: - Helpers

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VideoServiceTests.\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDirs.append(dir)
        return dir
    }

    private func makeDummyVideo(contents: String = "dummy") -> URL {
        let url = makeTempDir().appendingPathComponent("clip.mp4")
        try? contents.data(using: .utf8)!.write(to: url)
        return url
    }
}
