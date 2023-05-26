FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

PACKAGECONFIG_CONFARGS = ""

SRC_URI += " \
    file://09-swupdate-args \
    file://swupdate.cfg \
    "

SRC_URI:append:beaglebone-yocto = " file://10-remove-force-ro"

SRC_URI:append:rpi = " \
    file://swupdate.sh \
    file://swupdate-www.tar.gz \
    file://persistent/swupdate.cfg \
    file://persistent/swupdate.key.pub \
    file://persistent/09-swupdate-args \
    "

do_install:append() {
    install -m 0644 ${WORKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args

    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}
}

do_install:append:beaglebone-yocto() {
    # Recent swupdate as well as libubootenv handles force_ro flags automatically
    if ${@bb.utils.contains('DEPENDS','libubootenv','false','true',d)}; then
        install -m 0644 ${WORKDIR}/10-remove-force-ro ${D}${libdir}/swupdate/conf.d/
    fi
}

do_install:append:rpi() {
    # Update launch script
    install -m 0755 ${WORKDIR}/swupdate.sh ${D}${libdir}/swupdate/

    # Copy persistent configuration
    mkdir -p ${D}/opt/swupdate/conf.d
    install -m 0644 ${WORKDIR}/persistent/swupdate.cfg ${D}/opt/swupdate/
    install -m 0644 ${WORKDIR}/persistent/swupdate.key.pub ${D}/opt/swupdate/
    install -m 0644 ${WORKDIR}/persistent/09-swupdate-args ${D}/opt/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}/opt/swupdate/conf.d/09-swupdate-args
    sed -i "s#@MONGOOSE_PORT@#${MONGOOSE_PORT}#g" ${D}/opt/swupdate/conf.d/09-swupdate-args

    # Copy web interface
    mkdir -p ${D}/opt/swupdate/www
    tar xf ${WORKDIR}/swupdate-www.tar.gz -C ${D}/opt/swupdate/www/
}
