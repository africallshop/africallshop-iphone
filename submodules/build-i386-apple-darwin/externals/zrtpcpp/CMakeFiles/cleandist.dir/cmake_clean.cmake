FILE(REMOVE_RECURSE
  "CMakeFiles/cleandist"
)

# Per-language clean rules from dependency scanning.
FOREACH(lang)
  INCLUDE(CMakeFiles/cleandist.dir/cmake_clean_${lang}.cmake OPTIONAL)
ENDFOREACH(lang)
