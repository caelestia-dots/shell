install(DIRECTORY pam.d shaders DESTINATION "${INSTALL_QSCONFDIR}/assets")
install(PROGRAMS wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")
install(FILES bongocat.gif dino.png kurukuru.gif logo.svg DESTINATION "${INSTALL_QSCONFDIR}/assets")
