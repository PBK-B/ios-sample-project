import Foundation
import KSCrash_Reporting_Filters

public class KSCrashReportSinkFile: KSCrashReportFilterPipeline {
    // 输出日志目录
    public var filePath: String?
    public var fileDir: String?

    init(path: String?, dir: String? = nil) {
        filePath = path
        fileDir = dir
        super.init()
    }

    // 获取输出文件路径
    func outFilePath() -> String {
        if let filePath {
            // 输出到用户指定文件中
            return filePath
        }
        // var tmpFileName = "ios_client_crash.json" // 临时文件名
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY_MM_dd"
        let processInfo = ProcessInfo.processInfo
        let tmpFileName = "\(processInfo.processName)-\(formatter.string(from: .init()))-\(processInfo.processIdentifier).json"
        if let fileDir {
            // 输出到用户指定的文件夹中
            return fileDir + "/" + tmpFileName
        }
        return NSTemporaryDirectory() + "/" + tmpFileName
    }

    override public func filterReports(_ reports: [Any]!, onCompletion: KSCrashReportFilterCompletion!) {
        guard let report = reports.first else {
            print("KSCrashReportSinkFile error report is nil")
            return
        }
        do {
            let filePath = outFilePath()
            // 处理文件路径
            if var fileURL = URL(string: filePath) {
                fileURL.deleteLastPathComponent()
                let dirPath = fileURL.path
                if !FileManager.default.fileExists(atPath: dirPath) {
                    try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
                }
            }

            let reportObj = try KSJSONCodec.encode(report, options: KSJSONEncodeOptionSorted)
            try String(data: reportObj, encoding: .utf8)?.write(toFile: filePath, atomically: false, encoding: .utf8)
        } catch {
            print("KSCrashReportSinkFile error \(error)")
        }
        // print("KSCrashReportSinkFile reports:\(report)")
        kscrash_callCompletion(onCompletion, reports, true, nil)
    }
}
