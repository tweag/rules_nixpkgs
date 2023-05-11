{ %{args_with_defaults} }:
let
  value_or_function = %{def};
  value =
    if builtins.isFunction value_or_function then
      let
        formalArgs = builtins.functionArgs value_or_function;
        actualArgs = builtins.intersectAttrs formalArgs { inherit %{args}; };
      in
      value_or_function actualArgs
    else value_or_function;
in
value%{maybe_attr}
