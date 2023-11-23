{
  description = "A very basic flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/23.05"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
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
                 
        ns =     
          pkgs.writers.writePython3Bin "ns" {
            libraries = [ pkgs.python3Packages.sqlite-utils ];
          } ''   
          import os
          import sqlite3

          dbpath = "${nixsearch_create_db}/nix-search.db"
          connection = sqlite3.connect(dbpath)
          cursor = connection.cursor()
          package = f"%{os.argv[1]}%"
          rows = cursor.execute("SELECT * FROM packages WHERE name LIKE ? or description LIKE ? or longDescription LIKE ?", (package, package, package,)).fetchall()
          for row in rows:
              print("Package: {}\nVersion: {}\nDescription: {}\nLong Description:\n{}\n".format(*row))
          '';
        pkgs_json =
          builtins.toFile "pkgs.json" (import ./main.nix { inherit pkgs; });
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
            #nix-eval-jobs
            (python3.withPackages (ps: with ps; [ sqlite-utils rich ]))
            sqlite
          ];
        };
      };

    };
}
