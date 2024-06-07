import Foundation
import KSCrash_Reporting_Filters

public class KSCrashReportSinkFile: KSCrashReportFilterPipeline {
    // 输出日志目录
    public var filePath: String?

    init(path: String?) {
        filePath = path
        super.init()
    }

    // 获取输出文件路径
    func outFilePath() -> String {
        if let filePath {
            // 输出到用户指定文件中
            return filePath
        }
        var tmpFileName = "ios_client_crash.json" // 临时文件名
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
