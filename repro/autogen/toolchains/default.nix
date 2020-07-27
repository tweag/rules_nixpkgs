{ writeTextFile
}:

writeTextFile
{
   name = "toolchain-config";
   text = ''
foo = "21"
'';
   destination = "/variables.bzl";
}
