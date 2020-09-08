#!/usr/bin/env bash

rest_clis=('onezone-rest-cli' 'oneprovider-rest-cli' 'onepanel-rest-cli' 'cdmi-cli')

rest_clis

for (( i=0; i<${#rest_clis[*]}; i++ )) ; do
  rest_cli=${rest_clis[$i]}

  echo "Performance of $rest_cli before optimization:"
  time "$rest_cli"

  rest_cli_dir="/fast/$rest_cli/"
  mkdir -p "$rest_cli_dir"
  path_to_rest_cli="$(type -p $rest_cli)"
  mv "$path_to_rest_cli" "$rest_cli_dir"

  cd "$rest_cli_dir" || exit

  cat "$rest_cli" | split.pl "$PWD" - > "${rest_cli}-fast"
  chmod +x "${rest_cli}-fast"
  ln "$PWD/${rest_cli}-fast" "$path_to_rest_cli"

  echo "Performance of $rest_cli after optimization:"
  time "$rest_cli"
done

exit 0
