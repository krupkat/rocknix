with import <nixpkgs> { };

mkShell {
  packages = [

  ];

  EMULATION_DEVICE = "yes";
  ENABLE_32BIT = "no";
}
