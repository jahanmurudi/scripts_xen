LIC_FILES_CHKSUM = "file://COPYING;md5=d1a1e216f80b6d8da95fec897d0dbec9"

XEN_URL = "git://github.com/jahanmurudi/xen.git;protocol=https;branch=xen-4.20-stable-h3sk-kf"
XEN_REL = "4.20"
XEN_REV = "7ccb488f8752a69f41f820a44ce618e3d3b8fb4f"

do_install:append() {
    rm -f ${D}/usr/lib/xen/bin/xen-9pfsd
}

