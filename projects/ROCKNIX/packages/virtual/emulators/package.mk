# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="emulators"
PKG_LICENSE="GPLv2"
PKG_SITE="https://rocknix.org"
PKG_SECTION="emulation" # Do not change to virtual or makeinstall_target will not execute.
PKG_LONGDESC="Emulation metapackage."
PKG_TOOLCHAIN="manual"

PKG_EMUS="pico-8 portmaster"

EMUS_32BIT=""

PKG_RETROARCH="core-info libretro-database retroarch retroarch-assets retroarch-joypads retroarch-overlays retropie-shaders slang-shaders"

LIBRETRO_CORES="dosbox-pure-lr gambatte-lr mgba-lr freej2me-lr"

PKG_DEPENDS_TARGET+=" common-shaders glsl-shaders"

# Split building emulators into 2 stages, needed to fit the jobs into the 6 hour GH runner time limit.
case "${TARGET_TYPE}" in
  cores_only)
    PKG_DEPENDS_TARGET+=" ${LIBRETRO_CORES}"
    ;;
  emus_only)
    PKG_DEPENDS_TARGET+=" ${PKG_EMUS} ${EMUS_32BIT} ${PKG_RETROARCH}"
    ;;
  none)
    ;;
  *)
    PKG_DEPENDS_TARGET+=" ${PKG_EMUS} ${EMUS_32BIT} ${PKG_RETROARCH} ${LIBRETRO_CORES}"
    ;;
esac

install_script() {
  if [ ! -d "${INSTALL}/usr/config/modules" ]; then
    mkdir -p ${INSTALL}/usr/config/modules
  fi
  cp -rf ${PKG_DIR}/sources/"${1}" ${INSTALL}/usr/config/modules
  chmod 0755 ${INSTALL}/usr/config/modules/"${1}"
}

makeinstall_target() {
  ### Flush cache from previous builds
  clean_es_cache
  clean_doc_cache

  ### Add bezels directory
  add_system_dir /storage/roms/bezels

  ### Add BIOS directory
  add_system_dir /storage/roms/bios

  ### Add music directory
  add_system_dir /storage/roms/music

  ### Add save states directory
  add_system_dir /storage/roms/savestates

  ### Add themes directory
  add_system_dir /storage/roms/themes

  ### Apply documentation header
  start_system_doc

  ### Nintendo GameBoy
  add_emu_core gb retroarch gambatte true
  add_es_system gb

  ### Nintendo GameBoy Advance
  add_emu_core gba retroarch mgba true
  add_es_system gba

  ### Nintendo GameBoy Color
  add_emu_core gbc retroarch gambatte true
  add_es_system gbc

  ### Sun Microsystems J2ME
  add_emu_core j2me retroarch freej2me true
  add_es_system j2me

  ### Microsoft MS-DOS
  add_emu_core pc retroarch dosbox_pure true
  add_es_system pc

  ### Lexaloffle PICO-8
  add_emu_core pico-8 pico-8 pico8 true
  add_es_system pico-8

  ### PC Ports
  add_emu_core ports portmaster portmaster true
  add_es_system ports

  ### Tools
  add_es_system tools

  ### Screenshots
  add_es_system imageviewer

  ### Create es_systems
  mk_es_systems

  ### Generate document
  mk_system_doc

  mkdir -p ${INSTALL}/usr/config/emulationstation
  cp -f ${ESTMP}/es_systems.cfg ${INSTALL}/usr/config/emulationstation

  if [ "${WINDOWMANAGER}" = "weston" ]; then
    sed -i 's~%RUNCOMMAND%~weston-terminal --command="%ROM%"~g' ${INSTALL}/usr/config/emulationstation/es_systems.cfg
  elif [ "${WINDOWMANAGER}" = "swaywm-env" ]; then
    sed -i 's~%RUNCOMMAND%~/usr/bin/foot %ROM%~g' ${INSTALL}/usr/config/emulationstation/es_systems.cfg
  else
    sed -i 's~%RUNCOMMAND%~/usr/bin/run %ROM%~g' ${INSTALL}/usr/config/emulationstation/es_systems.cfg
  fi

  ### Automount should handle this.
  cp -f ${ESTMP}/system-dirs.conf ${INSTALL}/usr/config

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/mkcontroller ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/lib/autostart/common
  cp ${PKG_DIR}/autostart/* ${INSTALL}/usr/lib/autostart/common
  chmod 0755 ${INSTALL}/usr/lib/autostart/common/*
}
