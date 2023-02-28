Generate and watch SVGs with
```
NAMES=( module_deps transitive_tags )
(
  for name in ${NAMES[@]}; do
    d2 --sketch -t 104 --layout=elk -w assets/$name.d2 assets/$name.svg &
  done
  wait
)
```
