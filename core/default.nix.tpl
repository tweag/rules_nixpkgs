{%{args_with_defaults}}:
let
  x = %{def};
  y = if builtins.isFunction x then
        let
          formalArgs = builtins.functionArgs x;
          actualArgs = builtins.intersectAttrs formalArgs {inherit %{args};};
        in
           x actualArgs
       else x;
in
  y%{maybe_sel}
