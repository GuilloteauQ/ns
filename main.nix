{ pkgs }:
let
    unknown = x: set: if (builtins.isAttrs set) && (builtins.hasAttr x set) then builtins.getAttr x set else "unknown";
    getDescription = pkg: if builtins.hasAttr "meta" pkg then
                    if builtins.hasAttr "description" pkg.meta then pkg.meta.description else "" else "";
    getLongDescription = pkg: if builtins.hasAttr "meta" pkg then
                    if builtins.hasAttr "longDescription" pkg.meta then pkg.meta.longDescription else "" else "";

    # isBroken = pkg: (builtins.isAttrs pkg) && (((builtins.hasAttr "broken" pkg) && (pkg.broken)) || ((builtins.hasAttr "meta" pkg) && (builtins.hasAttr "broken" pkg.meta) && pkg.meta.broken));
in

builtins.toJSON (builtins.mapAttrs (name: pkg: let r = builtins.tryEval pkg; in if r.success && (builtins.isAttrs pkg) then {
        name = name;
        version = unknown "version" pkg;
        description = getDescription pkg;
        longDescription = getLongDescription pkg;
} else {}) (
    #pkgs //
    pkgs.python3Packages //
    #pkgs.rPackages //
    {}))
