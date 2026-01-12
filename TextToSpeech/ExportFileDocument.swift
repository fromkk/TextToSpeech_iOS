import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ExportFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.mp3]

    init(configuration: ReadConfiguration) throws {
      fatalError("not implemented")
    }

    let fileExporter: @Sendable () throws -> URL
    init(_ fileExporter: @escaping @Sendable () throws -> URL) {
      self.fileExporter = fileExporter
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
      let url = try fileExporter()
      let data = try Data(contentsOf: url, options: [])
      let fileWrapper = FileWrapper(regularFileWithContents: data)
      fileWrapper.filename = url.path().split(separator: "/").last.map(
        String.init
      )
      return fileWrapper
    }

    enum ExportError: Error {
      case fileExportFailed
    }
  }
