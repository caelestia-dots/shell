install(DIRECTORY google-sans-flex pam.d DESTINATION "${INSTALL_QSCONFDIR}/assets")
install(PROGRAMS wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")
install(FILES bongocat.gif dino.png kurukuru.gif logo.svg wallpaper.webp DESTINATION "${INSTALL_QSCONFDIR}/assets")
