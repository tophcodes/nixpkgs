{
  lib,
  stdenv,
  cctools,
  fetchurl,
  fixDarwinDylibNames,
  nix-update-script,
  pkg-config,
  xcbuild,
  zig_0_17,

  optimize ? "ReleaseFast",
  simd ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty-vt";
  version = "1.0.0";

  src = fetchurl {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}.tar.gz";
    hash = "sha256-Sm73WL5yGSPhlp57gbRD3MktjdP7WjlgDAOogXp1NnY=";
  };

  # Every Zig package the build needs, unpacked in the layout of Zig's package cache.
  deps = fetchurl {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}-deps.tar.gz";
    hash = "sha256-TV6l5Ejkx+qPtVzLqoZo8ql9RPQ4zugx4rfs0WLYXCk=";
  };

  postUnpack = ''
    unpackFile "$deps"
  '';

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    zig_0_17
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
    fixDarwinDylibNames
    xcbuild
  ];

  buildInputs = [ ];

  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    substituteInPlace src/build/LibtoolStep.zig \
      --replace-fail /bin/cp cp \
      --replace-fail /usr/bin/ranlib ranlib
    substituteInPlace src/build/GhosttyLibVt.zig \
      --replace-fail /bin/ln ln
    substituteInPlace pkg/apple-sdk/native_link.zig \
      --replace-fail /usr/bin/xcrun xcrun
  '';

  dontSetZigDefaultFlags = true;

  zigBuildFlags = [
    "--system"
    "../libghostty-vt-${finalAttrs.version}-deps"
    "-Dcpu=baseline"
    "-Doptimize=${optimize}"
    "-Dsimd=${lib.boolToString simd}"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "-Demit-xcframework=false"
  ];

  doCheck = false;

  outputs = [
    "out"
    "dev"
  ];

  postInstall = ''
    mkdir -p "$dev/lib"
    mv "$out/lib/libghostty-vt.a" "$dev/lib/"
  '';

  postFixup = ''
    substituteInPlace "$dev/lib/pkgconfig/libghostty-vt-static.pc" \
      --replace-fail "$out" "$dev"
    substituteInPlace "$dev/lib/cmake/ghostty-vt/ghostty-vt-config.cmake" \
      --replace-fail 'set(_ghostty_vt_shared_libdir "''${_ghostty_vt_libdir}")' \
      "set(_ghostty_vt_shared_libdir \"$out/lib\")"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/ghostty-org/ghostty"
      "--version-regex"
      "^vt-(.+)$"
      "--subpackage"
      "deps"
    ];
  };

  meta = {
    description = "Ghostty's VT (terminal sequence) parsing library";
    homepage = "https://ghostty.org/";
    license = lib.licenses.mit;
    pkgConfigModules = [
      "libghostty-vt"
      "libghostty-vt-static"
    ];
    maintainers = with lib.maintainers; [ domenkozar ];
    platforms = zig_0_17.meta.platforms;
  };
})
