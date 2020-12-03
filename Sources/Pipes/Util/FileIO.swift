import Foundation

class LineReader {
    private let file: UnsafeMutablePointer<FILE>!

    init(path: String) throws {
        guard let file = fopen(path, "r") else { throw PipeError.fileDoesNotExist(filename: path) }

        self.file = file
    }

    var nextLine: String? {
        var chars: UnsafeMutablePointer<CChar>? = nil
        var linecap: Int = 0

        defer { free(chars) }
        guard getline(&chars, &linecap, file) > 0 else { return nil }

        let line = String(cString: chars!)
        return line.last?.isNewline == true ? String(line.dropLast()) : line
    }

    deinit {
      fclose(file)
    }
}

extension LineReader: Sequence {
   public func  makeIterator() -> AnyIterator<String> {
      return AnyIterator<String> {
         return self.nextLine
      }
   }
}

class LineWriter {
    private let path: String
    private let append: Bool
    private let tmpHandle: FileHandle
    private let tmpURL: URL

    init(path: String, append: Bool) throws {
        let url = URL(fileURLWithPath: path)
        do {
            let tmpDir = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)

            self.path = path
            self.append = append
            self.tmpURL = tmpDir.appendingPathComponent("PIP_\(UUID().uuidString)")

            if append && FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.copyItem(at: url, to: tmpURL)
                self.tmpHandle = try FileHandle(forWritingTo: tmpURL)
                self.tmpHandle.seekToEndOfFile()
            } else {
                FileManager.default.createFile(atPath: tmpURL.path, contents: nil, attributes: nil)
                self.tmpHandle = try FileHandle(forWritingTo: tmpURL)
            }
        } catch let error {
            throw PipeError.unableToWriteToFile(path: path, error: error.localizedDescription)
        }

    }

    func write(_ record: String) {
        let line = "\(record)\n"
        tmpHandle.write(line.data(using: .utf8)!)
    }

    func close() throws {
        tmpHandle.closeFile()

        do {
            let url = URL(fileURLWithPath: path)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmpURL)
        } catch let error {
            throw PipeError.unableToWriteToFile(path: path, error: error.localizedDescription)
        }
    }
}
