{
    description = "Standalone SCOoOTER SoC and BlueJ debug demo";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/24.11";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, flake-utils, nixpkgs }:
        flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
            pkgs = import nixpkgs { inherit system; };
        in {
            devShells.default = pkgs.mkShellNoCC {
                LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
                    pkgs.stdenv.cc.cc.lib
                ];
                packages = with pkgs; [
                    gcc
                    # The wrapped compiler adds host hardening flags that are
                    # not supported when targeting bare-metal RISC-V.
                    llvmPackages.clang-unwrapped
                    llvmPackages.lld
                    llvmPackages.llvm
                    bluespec
                    openocd
                    gdb
                    iverilog
                    verilator
                    yosys
                ];
            };
        });
}
