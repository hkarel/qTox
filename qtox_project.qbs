import qbs
import qbs.File
import qbs.TextFile
import qbs.Process
import "qbs/imports/QbsUtl/qbsutl.js" as QbsUtl

Project {
    name: "qTox Project"
    minimumQbsVersion: "1.10.0"
    qbsSearchPaths: ["qbs"]

    // The attribute of output of additional information
    // in the file package_build_info, used to build a deb-package
    readonly property bool printPackegeBuildInfo: false

    property string toxPrefix: "toxcore/"
    property string useSmileys: "yes"

    property string sodiumVersion: "1.0.15"
    property string ffmpegVersion: "3.3.3"

    property string osName: osProbe.osName
    property string osVersion: osProbe.osVersion

    PropertyOptions {
        name: "toxPrefix"
        description: "Base dir with tox library sources"
    }
    PropertyOptions {
        name: "useSmileys"
        allowedValues: ["yes", "no", "min"]
        description: "Smileys variants"
    }

    Probe {
        id: versionProbe
        property string gitRevision: "build without git"
        property string gitDescribe: "Nightly"
        property string timestamp: ""

        configure: {
            gitRevision = QbsUtl.gitRevision(sourceDirectory);
            var process = new Process();
            try {
                process.setWorkingDirectory(sourceDirectory);
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

    Probe {
        id: osProbe
        property string osName: undefined
        property string osVersion: undefined

        configure: {
            if (qbs.hostOS.containsAny(["linux", "unix"])) {
                if (File.exists("/etc/os-release")) {
                    var file = new TextFile("/etc/os-release", TextFile.ReadOnly);
                    try {
                        var regex1 = /^ID=(.*)$/
                        var regex2 = /^VERSION_ID="?([^"]*)"?$/
                        while (true) {
                            var line = file.readLine();
                            if (!line)
                                break;

                            if (osName === undefined) {
                                var r = line.match(regex1);
                                if (r !== null)
                                    osName = r[1];
                            }
                            if (osVersion === undefined) {
                                var r = line.match(regex2);
                                if (r !== null)
                                    osVersion = r[1];
                            }
                        }
                    }
                    finally {
                        file.close();
                    }
                }
            }
            else {
                osName = qbs.hostOS[0];
                osVersion = qbs.hostOSVersion;
            }

            if (osName === undefined)
                throw new Error("OS name is undefined");
            if (osVersion === undefined)
                throw new Error("OS version is undefined");

            //console.info("=== osName ===");
            //console.info(osName);
            //console.info("=== osVersion ===");
            //console.info(osVersion);
        }
    }

    property var cppDefines: {
        var def = [
            "GIT_VERSION=\"" + versionProbe.gitRevision + "\"",
            "GIT_DESCRIBE=\"" + versionProbe.gitDescribe + "\"",
            "TIMESTAMP=\"" + versionProbe.timestamp + "\"",
        ];
        return def;
    }

    property string cxxLanguageVersion: "c++11"
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
