{ writeTextFile
}:

writeTextFile
{
   name = "toolchain-config";
   text = ''
foo = "22"
'';
   destination = "/variables.bzl";
}
