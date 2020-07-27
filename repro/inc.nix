{ writeTextFile
}:

# This is just writing a file in the nix store with a default value
writeTextFile
{
   name = "toolchain-config";
   text = ''
foo = "22"
'';
   destination = "/variables.bzl";
}
