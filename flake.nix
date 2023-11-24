{
  description = "Flake for ns";

  inputs = {
    # override this one with the `nixpkgs` that you want to query
    nixpkgs.url = "github:nixos/nixpkgs/23.05";
    # override this one only for the packages that build the packages
    nixpkgs_fixed.url = "github:nixos/nixpkgs/23.05";
  };

  outputs = { self, nixpkgs, nixpkgs_fixed }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs_fixed {
        inherit system;
      };
      pkgs_ns = import nixpkgs {
        inherit system;
        config.allowBroken = true;
      };
    in {
      packages.${system} = rec {
        nixsearch_db = pkgs.stdenv.mkDerivation {
            name = "nixsearch_db";
            version = nixpkgs.rev;
            src = ./.;
            buildInputs = [
                nixsearch_create_db
            ];
            buildPhase = ''
                mkdir -p $out
                cd $out
                nixsearch_create_db
            '';
            installPhase = ''
                echo pass
            '';  
        };
                 
        ns = pkgs.stdenv.mkDerivation rec {
          name = "ns";
          version = nixpkgs.rev;
          src = ./src;
          nativeBuildInputs = with pkgs; [
            gcc
            pkg-config
          ];
          buildInputs = with pkgs; [
            sqlite
            nixsearch_db
          ];
          buildPhase = ''
            mkdir -p $out/bin
            g++ -DDB_PATH="${nixsearch_db}/nix-search.db" $(pkg-config --libs --cflags sqlite3) -o $out/bin/ns main.cpp -O3
          '';
          installPhase = ''
            echo pass
          '';
        };
        pkgs_json =
          builtins.toFile "pkgs.json" (import ./main.nix { pkgs = pkgs_ns; });
        nixsearch_create_db =
          pkgs.writers.writePython3Bin "nixsearch_create_db" {
            libraries = [ pkgs.python3Packages.sqlite-utils ];
          } ''
            import json
            import sqlite3


            def get_tuple(name, x):
                version = str(x["version"]) if "version" in x else ""
                desc = x["description"] if "description" in x else ""
                long_desc = x["longDescription"] if "longDescription" in x else ""
                return (name, version, desc, long_desc)


            con = sqlite3.connect("nix-search.db")
            cur = con.cursor()
            cur.execute("CREATE TABLE packages(name,\
            version,\
            description,\
            longDescription)")
            pkgs_json = "${pkgs_json}"
            with open(pkgs_json, "r") as pkgs:
                data = json.loads(pkgs.read())
                to_insert = [get_tuple(name, x) for (name, x) in data.items()]
                cur.executemany("INSERT INTO packages VALUES(?, ?, ?, ?)", to_insert)
                con.commit()
          '';
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            (python3.withPackages (ps: with ps; [ sqlite-utils rich ]))
            sqlite
            pkg-config
          ];
        };
      };

    };
}
