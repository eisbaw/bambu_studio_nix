{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs)
    stdenv
    lib
    binutils
    fetchFromGitHub
    fetchpatch
    cmake
    ninja
    pkg-config
    wrapGAppsHook3
    boost183
    cereal
    cgal_5
    curl
    dbus
    eigen
    expat
    ffmpeg
    gcc-unwrapped
    glew
    glfw
    glib
    glib-networking
    gmp
    gst_all_1
    gtest
    gtk3
    hicolor-icon-theme
    ilmbase
    libpng
    mpfr
    nlopt
    opencascade-occt_7_6
    openvdb
    opencv
    pcre
    systemd
    tbb_2021_11
    webkitgtk_4_0
    wxGTK31
    xorg
    ;

  withSystemd = stdenv.hostPlatform.isLinux;

  wxGTK' =
    (wxGTK31.override {
      withCurl = true;
      withPrivateFonts = true;
      withWebKit = true;
    }).overrideAttrs
      (old: {
        configureFlags = old.configureFlags ++ [
          # Disable noisy debug dialogs
          "--enable-debug=no"
        ];
      });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "bambu-studio";
  version = "02.04.00.70";

  src = fetchFromGitHub {
    owner = "bambulab";
    repo = "BambuStudio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BrH8gKbc0y76wbWrQxU+0xMJcYAm4Gi/xmECVf6pGkI=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    binutils
    boost183
    cereal
    cgal_5
    curl
    dbus
    eigen
    expat
    ffmpeg
    gcc-unwrapped
    glew
    glfw
    glib
    glib-networking
    gmp
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gtk3
    hicolor-icon-theme
    ilmbase
    libpng
    mpfr
    nlopt
    opencascade-occt_7_6
    openvdb
    pcre
    tbb_2021_11
    webkitgtk_4_0
    wxGTK'
    xorg.libX11
    opencv
  ]
  ++ lib.optionals withSystemd [ systemd ]
  ++ finalAttrs.checkInputs;

  patches = [
    # Fix for webkitgtk linking
    ./patches/0001-not-for-upstream-CMakeLists-Link-against-webkit2gtk-.patch
    # Fix an issue with opencv linking
    ./patches/dont-link-opencv-world-bambu.patch
    # Don't link osmesa
    ./patches/no-osmesa.patch
    # Don't link cereal
    ./patches/no-cereal.patch
    # Cmake 4 support
    ./patches/cmake.patch
    # Fix build with gcc15
    (fetchpatch {
      name = "bambu-studio-include-stdint-header.patch";
      url = "https://github.com/bambulab/BambuStudio/commit/434752bf643933f22348d78335abe7f60550e736.patch";
      hash = "sha256-vWqTM6IHL/gBncLk6gZHw+dFe0sdVuPdUqYeVJUbTis=";
    })
  ];

  doCheck = true;
  checkInputs = [ gtest ];

  separateDebugInfo = true;

  # The build system uses custom logic - defined in
  # cmake/modules/FindNLopt.cmake in the package source - for finding the nlopt
  # library, which doesn't pick up the package in the nix store.
  NLOPT = nlopt;

  NIX_CFLAGS_COMPILE = toString [
    "-DBOOST_TIMER_ENABLE_DEPRECATED"
    # Disable compiler warnings that clutter the build log.
    "-Wno-ignored-attributes"
    "-I${opencv}/include/opencv4"
  ];

  NIX_LDFLAGS = lib.optionalString withSystemd "-ludev" + " -L${opencv}/lib -lopencv_imgcodecs";

  prePatch = ''
    # Since version 2.5.0 of nlopt we need to link to libnlopt
    sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake
  '';

  cmakeFlags = [
    "-DSLIC3R_STATIC=0"
    "-DSLIC3R_FHS=1"
    "-DSLIC3R_GTK=3"
    "-DFLATPAK=1"
    "-DBBL_RELEASE_TO_PUBLIC=1"
    "-DBBL_INTERNAL_TESTING=0"
    "-DDEP_WX_GTK3=ON"
    "-DSLIC3R_BUILD_TESTS=0"
    "-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/lib"
      # Fixes intermittent crash - upstream links glew statically
      --prefix LD_PRELOAD : "${glew.out}/lib/libGLEW.so"
    )
  '';

  postInstall = ''
    mv $out/LICENSE.txt $out/share/BambuStudio/LICENSE.txt
    mv $out/README.md $out/share/BambuStudio/README.md
  '';

  meta = {
    description = "PC Software for BambuLab's 3D printers";
    homepage = "https://github.com/bambulab/BambuStudio";
    changelog = "https://github.com/bambulab/BambuStudio/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Plus;
    mainProgram = "bambu-studio";
    platforms = lib.platforms.linux;
  };
})
