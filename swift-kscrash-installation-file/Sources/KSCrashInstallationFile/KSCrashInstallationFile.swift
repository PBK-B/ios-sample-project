import Foundation
import KSCrash_Installations

public struct KSCrashInstallationFileOpts {
    public var outFilePath: String?
    public var outDirPath: String?
    public var reportStyle: KSAppleReportStyle?

    public init(outFilePath: String? = nil, reportStyle: KSAppleReportStyle? = nil) {
        self.outFilePath = outFilePath
        self.reportStyle = reportStyle
    }
}

public class KSCrashInstallationFile: KSCrashInstallationConsole {
    private static var shared: KSCrashInstallationFile?

    static var sharedInstance: KSCrashInstallationFile? = {
        if KSCrashInstallationFile.shared == nil {
            KSCrashInstallationFile.shared = KSCrashInstallationFile(opts: KSCrashInstallationFileOpts())
        }
        return KSCrashInstallationFile.shared
    }()

    // 输出日志目录
    public var options: KSCrashInstallationFileOpts

    public init(opts: KSCrashInstallationFileOpts) {
        options = opts
        super.init(requiredProperties: nil)
    }

    override public func install() {
        var filters: [KSCrashReportFilter] = []
        if let style = options.reportStyle {
            // FIXME: KSCrashReportFilterAppleFmt 格式输出待实现
            // reportStyle: KSAppleReportStyleSymbolicated
            filters.append(KSCrashReportFilterAppleFmt(reportStyle: style))
        }
        filters.append(KSCrashReportSinkFile(path: options.outFilePath, dir: options.outDirPath))

        // addPreFilter(KSCrashReportFilterPipelineRef(filters: filters))
        for item in filters {
            addPreFilter(item)
        }

        super.install()
    }
}
