import Darwin

var arguments = CommandLine.arguments
arguments[0] = "mount"
arguments[arguments.count - 2] = String(cString: getenv("UNLOCALFS_VOLUME_NAME")) + ":/"
arguments.insert(contentsOf: ["-o", "localhost"], at: 1)
execv("/sbin/mount", arguments.map { strdup($0) } + [nil])
perror("/sbin/mount")
exit(EX_OSERR)
