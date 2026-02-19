
#!/usr/bin/env bash
#addalias.sh - A CLI that adds an alias to .bashrc

# addalias "name" "Command"
# alias "name"="Command"
# reset the terminal
# easy!

set -euo pipefail
IFS=$'\n\t'

: "${DEBUG:=false}"
: "${TRACE:=false}"
if [[ $TRACE == true ]]; then
  export PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}()  '
  set -x
  set -E
  trap 'err "ERR at ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (status=$?)"' ERR
elif [[ $DEBUG == true ]]; then
  set -x
fi


if [[ -t 2 ]]; then
  _b=$'\033[1m'; _d=$'\033[0m'
  _red=$'\033[31m'; _yel=$'\033[33m'; _grn=$'\033[32m'; _blu=$'\033[34m'
else
  _b='' _d='' _red='' _yel='' _grn='' _blu=''
fi

log()  { printf '%s[%s]%s %s\n' "$_b$_blu" "$SCRIPT_NAME" "$_d" "$*" >&2; }
warn() { printf '%s[WARN]%s %s\n' "$_b$_yel" "$_d" "$*" >&2; }
ok()   { printf '%s[ OK ]%s %s\n' "$_b$_grn" "$_d" "$*" >&2; }
die()  { printf '%s[ ERR ]%s %s\n' "$_b$_red" "$_d" "$*" >&2; exit 1; }
err() { printf '%s[ ERR ]%s %s\n' "$_b$_red" "$_d" "$*" >&2;}

print_help(){
  cat <<'EOF'
  Usage:
    addalias "name" "CMD"
    addalias -n/-N/--name "name" -c/-C/--command "CMD"
EOF
}

yes_no(){
  local prompt="$1"
  read -r -p "[ ? ] $prompt [Y/n]: " yn
  case $yn in
    [Yy]*) printf "y" ;;
    [Nn]*) printf "n" ;;
    *) die "Please answer yes or no.";;
  esac
}

FILE=${FILE:-"$HOME/.bashrc"}
NAME=""
CMD=""

case "$(basename $SHELL)" in
  bash) FILE="$HOME/.bashrc";;
  zsh) FILE="$HOME/.zshrc";;
  *) FILE="$HOME/.profile";;
esac

(( $# == 0 )) && { print_help ; exit 0 ;} # no arg option
while (($#)); do
  case "$1" in
    -n|-N|--name) NAME="${2:?}" ; shift 2 ;;
    -c|-C|--command) CMD="${2:?}" ; shift 2 ;;
    -l|-L|--list) grep --color=always -n "alias" "$FILE" ; exit 0 ;;
    --) shift ; break ;;
    -*) die "Unknown option: $1" ;;
    *) NAME="${1:-?$(die "no name entry")}" ; CMD="${2:?$(die "No cmd entry")}" ; shift 2;
  esac
done

[[ -z "$NAME" ]] && die "Name can not be empty"
[[ -z "$CMD" ]]  && die "Command can not be empty"

if grep -qE "^alias[[:space:]]+${NAME}=" "$FILE"; then
  warn "An alias already exists under the name ${NAME} here:"
  grep -nE "^alias[[:space:]]+${NAME}=" "$FILE"

  if [[ "$(yes_no "change the line?")" == "y" ]]; then
    new_line="alias ${NAME}=\"${CMD}\""
    sed -i -E "s|^alias[[:space:]]+${NAME}=.*|${new_line}|" "$FILE" \
      || die "Couldn't edit alias"
    ok "Updated alias ${NAME}"
    printf '\nReload with:\n  source %s\n\n' "$FILE"
    exit 0
  else
    echo "Aborted." >&2
    exit 0
  fi
fi

[[ -z "$FILE" ]] && die "${FILE} doesn't exist"

echo -e "alias ${NAME}=\"${CMD}\"" >> "$FILE" && { \
printf '\nOpen a new terminal or run:\n  source %s\n\n' "$FILE";}
