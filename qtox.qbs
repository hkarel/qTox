import qbs
import qbs.TextFile
import QbsUtl
import ProbExt

Product {
    name: "qTox"
    type: "application"
    targetName: "qtox"
    consoleApplication: false
    destinationDirectory: "./bin"

    property bool platformExtensions: true

    Depends { name: "cpp" }
    Depends { name: "cppstdlib" }
    Depends { name: "lib.sodium" }
    Depends { name: "lib.ffmpeg" }
    Depends { name: "FilterAudio" }
    Depends { name: "ToxMessenger" }
    Depends { name: "ToxCore" }
    Depends { name: "ToxNetwork" }
    //Depends { name: "ToxAV" }
    //Depends { name: "ToxDNS" }
    Depends { name: "ToxGroup" }
    Depends { name: "SonnetCore" }
    Depends { name: "SonnetGenTrigrams" }
    Depends { name: "SonnetParseTrigrams" }
    Depends { name: "SonnetUi" }
    Depends { name: "Qt"; submodules: ["core", "network", "gui", "widgets", "dbus", "svg", "xml"] }

    lib.sodium.version:   project.sodiumVersion
    lib.sodium.useSystem: project.useSystemSodium

    lib.ffmpeg.version: "4.0"
    lib.ffmpeg.dynamicLibraries: [
        "avdevice",
        "avfilter",
        "avformat",
        "swresample",
        "swscale",
        "avcodec",
        "avutil",
    ]

    Probe {
        id: productProbe
        property string projectBuildDirectory: project.buildDirectory
        property string osName: project.osName
        property string osVersion: project.osVersion
        property string cppstdlibPath: cppstdlib.path
        property var qt: Qt
        property var libs: [
            lib.ffmpeg,
            lib.sodium,
        ]

        configure: {
            var file = new TextFile(projectBuildDirectory + "/package_build_info", TextFile.WriteOnly);
            for (var n in libs) {
                var lib = libs[n];
                for (var i in lib.dynamicLibraries) {
                    file.writeLine(lib.libraryPath + ("/lib{0}.so*").format(lib.dynamicLibraries[i]));
                }
            }
            var libFiles = []
            libFiles.push(qt.core.libFilePathRelease);
            libFiles.push(qt.network.libFilePathRelease);
            libFiles.push(qt.gui.libFilePathRelease);
            libFiles.push(qt.widgets.libFilePathRelease);
            libFiles.push(qt.dbus.libFilePathRelease);
            libFiles.push(qt.svg.libFilePathRelease);
            libFiles.push(qt.xml.libFilePathRelease);
            libFiles.push(qt.core.libPath + "/libQt5XcbQpa.so.5");
            libFiles.push(qt.core.libPath + "/libicui18n.so.56");
            libFiles.push(qt.core.libPath + "/libicuuc.so.56");
            libFiles.push(qt.core.libPath + "/libicudata.so.56");

            // For FFmpeg
            //libFiles.push("/usr/lib/x86_64-linux-gnu/libvidstab.so.1");
            //libFiles.push("/usr/lib/x86_64-linux-gnu/libzimg.so.2");
            //libFiles.push("/usr/lib/x86_64-linux-gnu/libfdk-aac.so.1");
            //libFiles.push("/usr/lib/x86_64-linux-gnu/libx265.so.130");

            //if (osName === "ubuntu" && osVersion === "16.04")
            //    libFiles.push("/usr/lib/x86_64-linux-gnu/libx264.so.152");

            for (var i in libFiles)
                file.writeLine(libFiles[i].replace(/\.so\..*$/, ".so*"));

            if (!cppstdlibPath.startsWith("/usr/lib", 0)) {
                file.writeLine(cppstdlibPath + "/" + "libstdc++.so*");
                file.writeLine(cppstdlibPath + "/" + "libgcc_s.so*");
            }
            file.close();

            file = new TextFile(projectBuildDirectory + "/package_build_info2", TextFile.WriteOnly);
            file.writeLine(qt.core.pluginPath + "/*");
            file.close();
        }
    }
    ProbExt.LibValidationProbe {
        id: libValidation
        checkingLibs: [lib.sodium, lib.ffmpeg]
    }

    cpp.defines: project.cppDefines.concat([
        "QTOX_PLATFORM_EXT",
        "ENABLE_SYSTRAY_STATUSNOTIFIER_BACKEND",
        "ENABLE_SYSTRAY_GTK_BACKEND",
        "USE_FILTERAUDIO",
        "LOG_TO_FILE",
        "SPELL_CHECKING",
    ])

    cpp.cxxLanguageVersion: "c++14"
    cpp.cxxFlags: {
        var flags = project.cxxFlags.concat([
            "-Wno-unused-parameter",
            //"-fno-exceptions",
            "-fno-rtti",
            "-Wstrict-overflow",
            "-Wstrict-aliasing",
            //"-Werror",
        ]);

        if (!qbs.targetOS.contains("windows")) {
            flags = flags.concat([
                "-fstack-protector-all",
                "-Wstack-protector",
            ]);
        }
        return flags;
    }

    Properties {
        condition: qbs.targetOS.contains("unix")
                   && !qbs.targetOS.containsAny(["ios", "darwin"])
        cpp.driverFlags: outer.concat([
            "-Wl,-z,now",
            "-Wl,-z,relro",
        ])
    }

    cpp.includePaths: [
        "./",
    ]

    cpp.systemIncludePaths: QbsUtl.concatPaths([
            "/usr/include/atk-1.0",
            "/usr/include/cairo",
            "/usr/include/gdk-pixbuf-2.0",
            "/usr/include/glib-2.0",
            "/usr/include/gtk-2.0",
            "/usr/include/pango-1.0",
            "/usr/lib/x86_64-linux-gnu/gtk-2.0/include",
            "/usr/lib/x86_64-linux-gnu/glib-2.0/include",
        ],
        lib.ffmpeg.includePath,
        lib.sodium.includePath
    );

    cpp.rpaths: QbsUtl.concatPaths(
        cppstdlib.path,
        lib.sodium.libraryPath,
        lib.ffmpeg.libraryPath,
        "/opt/qtox/lib"
        //"$ORIGIN/../lib/qtox"
    )

    cpp.libraryPaths: QbsUtl.concatPaths(
        lib.sodium.libraryPath,
        lib.ffmpeg.libraryPath
    )

    cpp.dynamicLibraries: {
        var libs = [
            "dl",
            "X11",
            "Xss",
            "glib-2.0",
            "gobject-2.0",
            "gdk_pixbuf-2.0",
            "gtk-x11-2.0",
            "gdk-x11-2.0",
            "gio-2.0",
            "cairo",
            "opus",
            "openal",
            "qrencode",
            "exif",
            "sqlite3",
            "z",
        ].concat(
            lib.sodium.dynamicLibraries,
            lib.ffmpeg.dynamicLibraries
        );

        if (project.osName === "ubuntu" && project.osVersion === "16.04") {
            libs.push("sndio");
            libs.push("gsm");
            libs.push("openjp2");
        }

        // Spell checker
        libs.push("hunspell");

        return libs;
    }

    cpp.staticLibraries: [
        // Version VPX must be not less than 1.5.0
        "/usr/lib/x86_64-linux-gnu/libvpx.a",
    ]

    Group {
        name: "resources"
        files: "res.qrc"
    }
    Group {
        name: "smileys"
        condition: project.useSmileys === "min"
        files: "smileys/smileys.qrc"
    }
    Group {
        name: "smileys emojione"
        condition: project.useSmileys === "yes"
        files: "smileys/emojione.qrc"
    }

    Group {
        name: "translations"
        files: ["translations/*.ts"]
    }
    Group {
        fileTagsFilter: ["qm"]
        fileTags: ["qt.core.resource_data"]
    }
    Qt.core.resourceFileBaseName: "translations"
    Qt.core.resourcePrefix: "translations"

    files: {
        var f = [
            "src/audio/audio.cpp",
            "src/audio/audio.h",
            "src/audio/backend/openal.cpp",
            "src/audio/backend/openal.h",
            "src/audio/backend/openal2.cpp",
            "src/audio/backend/openal2.h",
            "src/audio/iaudiosettings.h",
            "src/chatlog/chatlinecontent.cpp",
            "src/chatlog/chatlinecontent.h",
            "src/chatlog/chatlinecontentproxy.cpp",
            "src/chatlog/chatlinecontentproxy.h",
            "src/chatlog/chatline.cpp",
            "src/chatlog/chatline.h",
            "src/chatlog/chatlog.cpp",
            "src/chatlog/chatlog.h",
            "src/chatlog/chatmessage.cpp",
            "src/chatlog/chatmessage.h",
            "src/chatlog/content/filetransferwidget.cpp",
            "src/chatlog/content/filetransferwidget.h",
            "src/chatlog/content/image.cpp",
            "src/chatlog/content/image.h",
            "src/chatlog/content/notificationicon.cpp",
            "src/chatlog/content/notificationicon.h",
            "src/chatlog/content/spinner.cpp",
            "src/chatlog/content/spinner.h",
            "src/chatlog/content/text.cpp",
            "src/chatlog/content/text.h",
            "src/chatlog/content/timestamp.cpp",
            "src/chatlog/content/timestamp.h",
            "src/chatlog/customtextdocument.cpp",
            "src/chatlog/customtextdocument.h",
            "src/chatlog/documentcache.cpp",
            "src/chatlog/documentcache.h",
            "src/chatlog/pixmapcache.cpp",
            "src/chatlog/pixmapcache.h",
            "src/chatlog/textformatter.cpp",
            "src/chatlog/textformatter.h",
            "src/chatlog/toxfileprogress.cpp",
            "src/chatlog/toxfileprogress.h",
            "src/core/coreav.cpp",
            "src/core/coreav.h",
            "src/core/core.cpp",
            "src/core/corefile.cpp",
            "src/core/corefile.h",
            "src/core/core.h",
            "src/core/dhtserver.cpp",
            "src/core/dhtserver.h",
            "src/core/icoresettings.h",
            "src/core/toxcall.cpp",
            "src/core/toxcall.h",
            "src/core/toxencrypt.cpp",
            "src/core/toxencrypt.h",
            "src/core/toxfile.cpp",
            "src/core/toxfile.h",
            "src/core/toxid.cpp",
            "src/core/toxid.h",
            "src/core/toxpk.cpp",
            "src/core/toxpk.h",
            "src/core/toxstring.cpp",
            "src/core/toxstring.h",
            "src/core/toxoptions.cpp",
            "src/core/toxlogger.cpp",
            "src/core/toxlogger.h",
            "src/core/toxoptions.h",
            "src/friendlist.cpp",
            "src/friendlist.h",
            "src/grouplist.cpp",
            "src/grouplist.h",
            "src/ipc.cpp",
            "src/ipc.h",
            "src/model/about/aboutfriend.cpp",
            "src/model/about/aboutfriend.h",
            "src/model/about/iaboutfriend.h",
            "src/model/chatroom/chatroom.h",
            "src/model/chatroom/friendchatroom.cpp",
            "src/model/chatroom/friendchatroom.h",
            "src/model/chatroom/groupchatroom.cpp",
            "src/model/chatroom/groupchatroom.h",
            "src/model/profile/iprofileinfo.h",
            "src/model/profile/profileinfo.cpp",
            "src/model/profile/profileinfo.h",
            "src/model/contact.cpp",
            "src/model/contact.h",
            "src/model/friend.cpp",
            "src/model/friend.h",
            "src/model/groupinvite.cpp",
            "src/model/groupinvite.h",
            "src/model/group.cpp",
            "src/model/group.h",
            "src/model/interface.h",
            //"src/net/autoupdate.cpp",
            //"src/net/autoupdate.h",
            "src/net/avatarbroadcaster.cpp",
            "src/net/avatarbroadcaster.h",
            "src/net/toxme.cpp",
            "src/net/toxme.h",
            "src/net/toxmedata.cpp",
            "src/net/toxmedata.h",
            "src/net/toxuri.cpp",
            "src/net/toxuri.h",
            "src/nexus.cpp",
            "src/nexus.h",
            "src/persistence/db/rawdatabase.cpp",
            "src/persistence/db/rawdatabase.h",
            "src/persistence/history.cpp",
            "src/persistence/history.h",
            "src/persistence/offlinemsgengine.cpp",
            "src/persistence/offlinemsgengine.h",
            "src/persistence/profile.cpp",
            "src/persistence/profile.h",
            "src/persistence/profilelocker.cpp",
            "src/persistence/profilelocker.h",
            "src/persistence/serialize.cpp",
            "src/persistence/serialize.h",
            "src/persistence/settings.cpp",
            "src/persistence/settings.h",
            "src/persistence/settingsserializer.cpp",
            "src/persistence/settingsserializer.h",
            "src/persistence/smileypack.cpp",
            "src/persistence/smileypack.h",
            "src/persistence/toxsave.cpp",
            "src/persistence/toxsave.h",
            "src/video/cameradevice.cpp",
            "src/video/cameradevice.h",
            "src/video/camerasource.cpp",
            "src/video/camerasource.h",
            "src/video/corevideosource.cpp",
            "src/video/corevideosource.h",
            "src/video/genericnetcamview.cpp",
            "src/video/genericnetcamview.h",
            "src/video/groupnetcamview.cpp",
            "src/video/groupnetcamview.h",
            "src/video/ivideosettings.h",
            "src/video/netcamview.cpp",
            "src/video/netcamview.h",
            "src/video/videoframe.cpp",
            "src/video/videoframe.h",
            "src/video/videomode.cpp",
            "src/video/videomode.h",
            "src/video/videosource.cpp",
            "src/video/videosource.h",
            "src/video/videosurface.cpp",
            "src/video/videosurface.h",
            "src/widget/about/aboutfriendform.cpp",
            "src/widget/about/aboutfriendform.h",
            "src/widget/categorywidget.cpp",
            "src/widget/categorywidget.h",
            "src/widget/chatformheader.cpp",
            "src/widget/chatformheader.h",
            "src/widget/circlewidget.cpp",
            "src/widget/circlewidget.h",
            "src/widget/contentdialog.cpp",
            "src/widget/contentdialog.h",
            "src/widget/contentdialogmanager.cpp",
            "src/widget/contentdialogmanager.h",
            "src/widget/contentlayout.cpp",
            "src/widget/contentlayout.h",
            "src/widget/emoticonswidget.cpp",
            "src/widget/emoticonswidget.h",
            "src/widget/flowlayout.cpp",
            "src/widget/flowlayout.h",
            "src/widget/form/addfriendform.cpp",
            "src/widget/form/addfriendform.h",
            "src/widget/form/chatform.cpp",
            "src/widget/form/chatform.h",
            "src/widget/form/filesform.cpp",
            "src/widget/form/filesform.h",
            "src/widget/form/genericchatform.cpp",
            "src/widget/form/genericchatform.h",
            "src/widget/form/groupchatform.cpp",
            "src/widget/form/groupchatform.h",
            "src/widget/form/groupinviteform.cpp",
            "src/widget/form/groupinviteform.h",
            "src/widget/form/groupinvitewidget.cpp",
            "src/widget/form/groupinvitewidget.h",
            "src/widget/form/loadhistorydialog.cpp",
            "src/widget/form/loadhistorydialog.h",
            "src/widget/form/profileform.cpp",
            "src/widget/form/profileform.h",
            "src/widget/form/setpassworddialog.cpp",
            "src/widget/form/setpassworddialog.h",
            "src/widget/form/searchsettingsform.cpp",
            "src/widget/form/searchsettingsform.h",
            "src/widget/form/settings/aboutform.cpp",
            "src/widget/form/settings/aboutform.h",
            "src/widget/form/settings/advancedform.cpp",
            "src/widget/form/settings/advancedform.h",
            "src/widget/form/settings/avform.cpp",
            "src/widget/form/settings/avform.h",
            "src/widget/form/settings/generalform.cpp",
            "src/widget/form/settings/generalform.h",
            "src/widget/form/settings/genericsettings.cpp",
            "src/widget/form/settings/genericsettings.h",
            "src/widget/form/settings/privacyform.cpp",
            "src/widget/form/settings/privacyform.h",
            "src/widget/form/settings/userinterfaceform.h",
            "src/widget/form/settings/userinterfaceform.cpp",
            "src/widget/form/settings/verticalonlyscroller.cpp",
            "src/widget/form/settings/verticalonlyscroller.h",
            "src/widget/form/settingswidget.cpp",
            "src/widget/form/settingswidget.h",
            "src/widget/form/tabcompleter.cpp",
            "src/widget/form/tabcompleter.h",
            "src/widget/friendlistlayout.cpp",
            "src/widget/friendlistlayout.h",
            "src/widget/friendlistwidget.cpp",
            "src/widget/friendlistwidget.h",
            "src/widget/friendwidget.cpp",
            "src/widget/friendwidget.h",
            "src/widget/genericchatitemlayout.cpp",
            "src/widget/genericchatitemlayout.h",
            "src/widget/genericchatitemwidget.cpp",
            "src/widget/genericchatitemwidget.h",
            "src/widget/genericchatroomwidget.cpp",
            "src/widget/genericchatroomwidget.h",
            "src/widget/groupwidget.cpp",
            "src/widget/groupwidget.h",
            "src/widget/gui.cpp",
            "src/widget/gui.h",
            "src/widget/loginscreen.cpp",
            "src/widget/loginscreen.h",
            "src/widget/maskablepixmapwidget.cpp",
            "src/widget/maskablepixmapwidget.h",
            "src/widget/notificationedgewidget.cpp",
            "src/widget/notificationedgewidget.h",
            "src/widget/notificationscrollarea.cpp",
            "src/widget/notificationscrollarea.h",
            "src/widget/passwordedit.cpp",
            "src/widget/passwordedit.h",
            "src/widget/qrwidget.cpp",
            "src/widget/qrwidget.h",
            "src/widget/searchform.cpp",
            "src/widget/searchform.h",
            "src/widget/splitterrestorer.cpp",
            "src/widget/splitterrestorer.h",
            "src/widget/style.cpp",
            "src/widget/style.h",
            "src/widget/systemtrayicon.cpp",
            "src/widget/systemtrayicon.h",
            "src/widget/systemtrayicon_private.h",
            "src/widget/tool/activatedialog.cpp",
            "src/widget/tool/activatedialog.h",
            "src/widget/tool/adjustingscrollarea.cpp",
            "src/widget/tool/adjustingscrollarea.h",
            "src/widget/tool/callconfirmwidget.cpp",
            "src/widget/tool/callconfirmwidget.h",
            "src/widget/tool/chattextedit.cpp",
            "src/widget/tool/chattextedit.h",
            "src/widget/tool/croppinglabel.cpp",
            "src/widget/tool/croppinglabel.h",
            "src/widget/tool/flyoutoverlaywidget.cpp",
            "src/widget/tool/flyoutoverlaywidget.h",
            "src/widget/tool/friendrequestdialog.cpp",
            "src/widget/tool/friendrequestdialog.h",
            "src/widget/tool/identicon.cpp",
            "src/widget/tool/identicon.h",
            "src/widget/tool/movablewidget.cpp",
            "src/widget/tool/movablewidget.h",
            "src/widget/tool/profileimporter.cpp",
            "src/widget/tool/profileimporter.h",
            "src/widget/tool/recursivesignalblocker.cpp",
            "src/widget/tool/recursivesignalblocker.h",
            "src/widget/tool/removefrienddialog.cpp",
            "src/widget/tool/removefrienddialog.h",
            "src/widget/tool/screengrabberchooserrectitem.cpp",
            "src/widget/tool/screengrabberchooserrectitem.h",
            "src/widget/tool/screengrabberoverlayitem.cpp",
            "src/widget/tool/screengrabberoverlayitem.h",
            "src/widget/tool/screenshotgrabber.cpp",
            "src/widget/tool/screenshotgrabber.h",
            "src/widget/tool/toolboxgraphicsitem.cpp",
            "src/widget/tool/toolboxgraphicsitem.h",
            "src/widget/translator.cpp",
            "src/widget/translator.h",
            "src/widget/widget.cpp",
            "src/widget/widget.h",
            "src/main.cpp",
        ];

        var ui = [
            "src/chatlog/content/filetransferwidget.ui",
            "src/loginscreen.ui",
            "src/mainwindow.ui",
            "src/widget/about/aboutfriendform.ui",
            "src/widget/form/loadhistorydialog.ui",
            "src/widget/form/profileform.ui",
            "src/widget/form/removefrienddialog.ui",
            "src/widget/form/setpassworddialog.ui",
            "src/widget/form/searchsettingsform.ui",
            "src/widget/form/settings/aboutsettings.ui",
            "src/widget/form/settings/advancedsettings.ui",
            "src/widget/form/settings/avform.ui",
            "src/widget/form/settings/generalsettings.ui",
            "src/widget/form/settings/privacysettings.ui",
            "src/widget/form/settings/userinterfacesettings.ui",
        ];
        f = f.concat(ui);

        if (qbs.targetOS.containsAny(["linux", "freebsd"])) {
            f = f.concat([
                "src/platform/camera/v4l2.cpp",
                "src/platform/camera/v4l2.h",

            ]);
        }

        if (qbs.targetOS.contains("unix")) {
            f = f.concat([
                "src/platform/posixsignalnotifier.cpp",
                "src/platform/posixsignalnotifier.h",
            ]);
        }

        if (platformExtensions === true) {
            f = f.concat([
                "src/platform/autorun.h",
                "src/platform/capslock.h",
                "src/platform/timer.h",
                "src/platform/x11_display.cpp",
            ]);
            if (qbs.targetOS.containsAny(["linux", "unix"]))
                f = f.concat([
                    "src/platform/autorun_xdg.cpp",
                    "src/platform/capslock_x11.cpp",
                    "src/platform/timer_x11.cpp",

                ]);
                //"src/platform/autorun_osx.cpp",
                //"src/platform/autorun_win.cpp",
                //"src/platform/capslock_osx.cpp",
                //"src/platform/capslock_win.cpp",
                //"src/platform/timer_osx.cpp",
                //"src/platform/timer_win.cpp",
        }

        if (qbs.targetOS.containsAny(["linux", "unix"])) {
            f = f.concat([
                "src/platform/statusnotifier/closures.c",
                "src/platform/statusnotifier/closures.h",
                "src/platform/statusnotifier/enums.c",
                "src/platform/statusnotifier/enums.h",
                "src/platform/statusnotifier/interfaces.h",
                "src/platform/statusnotifier/statusnotifier.c",
                "src/platform/statusnotifier/statusnotifier.h",
            ]);
        }

        return f;
    }

//    property var test: {
//        console.info("=== cpufeatures.x86_sse2 ===");
//        console.info(cpufeatures.x86_sse2);
//    }

}
