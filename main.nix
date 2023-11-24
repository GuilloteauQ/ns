{ pkgs }:
let
  unknown = x: set:
    if (builtins.isAttrs set) && (builtins.hasAttr x set) && (builtins.isString (builtins.getAttr x set)) then
      builtins.toString (builtins.getAttr x set)
    else
      "unknown";
  getDescription = pkg:
    if (builtins.hasAttr "meta" pkg) && (builtins.hasAttr "description" pkg.meta) then
        pkg.meta.description
    else
      "";
  getLongDescription = pkg:
    if (builtins.hasAttr "meta" pkg) && (builtins.hasAttr "longDescription" pkg.meta) then
        pkg.meta.longDescription
    else
      "";

  # isBroken = pkg: (builtins.isAttrs pkg) && (((builtins.hasAttr "broken" pkg) && (pkg.broken)) || ((builtins.hasAttr "meta" pkg) && (builtins.hasAttr "broken" pkg.meta) && pkg.meta.broken));

in builtins.toJSON (builtins.mapAttrs (name: pkg:
  let r = builtins.tryEval pkg;
  in if r.success && (builtins.isAttrs pkg) then

  if (builtins.hasAttr "version" pkg) && (builtins.isString pkg.version) then
  {
    inherit name;
    version = pkg.version;
    description = getDescription pkg;
    longDescription = getLongDescription pkg;
  } else
  { name = "${name}-plop"; version = "plop"; description = "plop"; longDescription = "plop";}
  else
    { }) (pkgs))# // pkgs.python3Packages // pkgs.rPackages // { }))
