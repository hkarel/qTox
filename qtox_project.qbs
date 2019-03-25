import qbs
import qbs.File
import qbs.TextFile
import qbs.Process
import "qbs/imports/QbsUtl/qbsutl.js" as QbsUtl
import "qbs/imports/ProbExt/OsProbe.qbs" as OsProbe

Project {
    name: "qTox Project"
    minimumQbsVersion: "1.10.0"
    qbsSearchPaths: ["qbs"]

    // The attribute of output of additional information
    // in the file package_build_info, used to build a deb-package
    readonly property bool printPackegeBuildInfo: false

    readonly property string sodiumVersion: "1.0.17"
    readonly property bool   useSystemSodium: false

    //readonly property string ffmpegVersion: "3.3.3"

    readonly property string useSmileys: "yes"
    PropertyOptions {
        name: "useSmileys"
        allowedValues: ["yes", "no", "min"]
        description: "Smileys variants"
    }

    readonly property string osName: osProbe.osName
    readonly property string osVersion: osProbe.osVersion

    OsProbe {
        id: osProbe
    }
    Probe {
        id: versionProbe
        property string gitRevision: "build without git"
        property string gitDescribe: "Nightly"
        property string timestamp: ""

        readonly property string projectSourceDirectory: project.sourceDirectory
        configure: {
            gitRevision = QbsUtl.gitRevision(projectSourceDirectory);
            var process = new Process();
            try {
                process.setWorkingDirectory(projectSourceDirectory);
                if (process.exec("git", ["describe", "--tags"], false) === 0)
                    gitDescribe = process.readLine().trim();

                if (process.exec("date", ["+%s"], false) === 0)
                    timestamp = process.readLine().trim();
            }
            finally {
                process.close();
            }
        }
    }

    property var cppDefines: {
        var def = [
            "GIT_VERSION=\"" + versionProbe.gitRevision + "\"",
            "GIT_DESCRIBE=\"" + versionProbe.gitDescribe + "\"",
            "TIMESTAMP=\"" + versionProbe.timestamp + "\"",
        ];
        if (qbs.buildVariant === "release")
            def.push("NDEBUG");

        return def;
    }

    property var cxxFlags: [
        "-Wall",
        "-Wextra",
        //"-Wno-unused-parameter",
    ]

    references: [
        "3rdparty/3rdparty.qbs",
        "qtox.qbs",
    ]
}
