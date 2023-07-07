#!/usr/bin/env bash

#set -xe


########## START library getoptions.bash ###########
# [getoptions] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
# shellcheck disable=SC2016
getoptions() {
	_error='' _on=1 _no='' _export='' _plus='' _mode='' _alt='' _rest='' _def=''
	_flags='' _nflags='' _opts='' _help='' _abbr='' _cmds='' _init=@empty IFS=' '
	[ $# -lt 2 ] && set -- "${1:?No parser definition}" -
	[ "$2" = - ] && _def=getoptions_parse

	i='					'
	while eval "_${#i}() { echo \"$i\$@\"; }"; [ "$i" ]; do i=${i#?}; done

	quote() {
		q="$2'" r=''
		while [ "$q" ]; do r="$r${q%%\'*}'\''" && q=${q#*\'}; done
		q="'${r%????}'" && q=${q#\'\'} && q=${q%\'\'}
		eval "$1=\${q:-\"''\"}"
	}
	code() {
		[ "${1#:}" = "$1" ] && c=3 || c=4
		eval "[ ! \${$c:+x} ] || $2 \"\$$c\""
	}
	sw() { sw="$sw${sw:+|}$1"; }
	kv() { eval "${2-}${1%%:*}=\${1#*:}"; }
	loop() { [ $# -gt 1 ] && [ "$2" != -- ]; }

	invoke() { eval '"_$@"'; }
	prehook() { invoke "$@"; }
	for i in setup flag param option disp msg; do
		eval "$i() { prehook $i \"\$@\"; }"
	done

	args() {
		on=$_on no=$_no export=$_export init=$_init _hasarg=$1 && shift
		while loop "$@" && shift; do
			case $1 in
				-?) [ "$_hasarg" ] && _opts="$_opts${1#-}" || _flags="$_flags${1#-}" ;;
				+?) _plus=1 _nflags="$_nflags${1#+}" ;;
				[!-+]*) kv "$1"
			esac
		done
	}
	defvar() {
		case $init in
			@none) : ;;
			@export) code "$1" _0 "export $1" ;;
			@empty) code "$1" _0 "${export:+export }$1=''" ;;
			@unset) code "$1" _0 "unset $1 ||:" "unset OPTARG ||:; ${1#:}" ;;
			*)
				case $init in @*) eval "init=\"=\${${init#@}}\""; esac
				case $init in [!=]*) _0 "$init"; return 0; esac
				quote init "${init#=}"
				code "$1" _0 "${export:+export }$1=$init" "OPTARG=$init; ${1#:}"
		esac
	}
	_setup() {
		[ "${1#-}" ] && _rest=$1
		while loop "$@" && shift; do kv "$1" _; done
	}
	_flag() { args '' "$@"; defvar "$@"; }
	_param() { args 1 "$@"; defvar "$@"; }
	_option() { args 1 "$@"; defvar "$@"; }
	_disp() { args '' "$@"; }
	_msg() { args '' _ "$@"; }

	cmd() { _mode=@ _cmds="$_cmds${_cmds:+|}'$1'"; }
	"$@"
	cmd() { :; }
	_0 "${_rest:?}=''"

	_0 "${_def:-$2}() {"
	_1 'OPTIND=$(($#+1))'
	_1 'while OPTARG= && [ $# -gt 0 ]; do'
	[ "$_abbr" ] && getoptions_abbr "$@"

	args() {
		sw='' validate='' pattern='' counter='' on=$_on no=$_no export=$_export
		while loop "$@" && shift; do
			case $1 in
				--\{no-\}*) i=${1#--?no-?}; sw "'--$i'|'--no-$i'" ;;
				--with\{out\}-*) i=${1#--*-}; sw "'--with-$i'|'--without-$i'" ;;
				[-+]? | --*) sw "'$1'" ;;
				*) kv "$1"
			esac
		done
		quote on "$on"
		quote no "$no"
	}
	setup() { :; }
	_flag() {
		args "$@"
		[ "$counter" ] && on=1 no=-1 v="\$((\${$1:-0}+\$OPTARG))" || v=''
		_3 "$sw)"
		_4 '[ "${OPTARG:-}" ] && OPTARG=${OPTARG#*\=} && set "noarg" "$1" && break'
		_4 "eval '[ \${OPTARG+x} ] &&:' && OPTARG=$on || OPTARG=$no"
		valid "$1" "${v:-\$OPTARG}"
		_4 ';;'
	}
	_param() {
		args "$@"
		_3 "$sw)"
		_4 '[ $# -le 1 ] && set "required" "$1" && break'
		_4 'OPTARG=$2'
		valid "$1" '$OPTARG'
		_4 'shift ;;'
	}
	_option() {
		args "$@"
		_3 "$sw)"
		_4 'set -- "$1" "$@"'
		_4 '[ ${OPTARG+x} ] && {'
		_5 'case $1 in --no-*|--without-*) set "noarg" "${1%%\=*}"; break; esac'
		_5 '[ "${OPTARG:-}" ] && { shift; OPTARG=$2; } ||' "OPTARG=$on"
		_4 "} || OPTARG=$no"
		valid "$1" '$OPTARG'
		_4 'shift ;;'
	}
	valid() {
		set -- "$validate" "$pattern" "$1" "$2"
		[ "$1" ] && _4 "$1 || { set -- ${1%% *}:\$? \"\$1\" $1; break; }"
		[ "$2" ] && {
			_4 "case \$OPTARG in $2) ;;"
			_5 '*) set "pattern:'"$2"'" "$1"; break'
			_4 "esac"
		}
		code "$3" _4 "${export:+export }$3=\"$4\"" "${3#:}"
	}
	_disp() {
		args "$@"
		_3 "$sw)"
		code "$1" _4 "echo \"\${$1}\"" "${1#:}"
		_4 'exit 0 ;;'
	}
	_msg() { :; }

	[ "$_alt" ] && _2 'case $1 in -[!-]?*) set -- "-$@"; esac'
	_2 'case $1 in'
	_wa() { _4 "eval 'set -- $1' \${1+'\"\$@\"'}"; }
	_op() {
		_3 "$1) OPTARG=\$1; shift"
		_wa '"${OPTARG%"${OPTARG#??}"}" '"$2"'"${OPTARG#??}"'
		_4 "$3"
	}
	_3 '--?*=*) OPTARG=$1; shift'
	_wa '"${OPTARG%%\=*}" "${OPTARG#*\=}"'
	_4 ';;'
	_3 '--no-*|--without-*) unset OPTARG ;;'
	[ "$_alt" ] || {
		[ "$_opts" ] && _op "-[$_opts]?*" '' ';;'
		[ ! "$_flags" ] || _op "-[$_flags]?*" - 'OPTARG= ;;'
	}
	[ "$_plus" ] && {
		[ "$_nflags" ] && _op "+[$_nflags]?*" + 'unset OPTARG ;;'
		_3 '+*) unset OPTARG ;;'
	}
	_2 'esac'
	_2 'case $1 in'
	"$@"
	rest() {
		_4 'while [ $# -gt 0 ]; do'
		_5 "$_rest=\"\${$_rest}" '\"\${$(($OPTIND-$#))}\""'
		_5 'shift'
		_4 'done'
		_4 'break ;;'
	}
	_3 '--)'
	[ "$_mode" = @ ] || _4 'shift'
	rest
	_3 "[-${_plus:++}]?*)" 'set "unknown" "$1"; break ;;'
	_3 '*)'
	case $_mode in
		@)
			_4 "case \$1 in ${_cmds:-*}) ;;"
			_5 '*) set "notcmd" "$1"; break'
			_4 'esac'
			rest ;;
		+) rest ;;
		*) _4 "$_rest=\"\${$_rest}" '\"\${$(($OPTIND-$#))}\""'
	esac
	_2 'esac'
	_2 'shift'
	_1 'done'
	_1 '[ $# -eq 0 ] && { OPTIND=1; unset OPTARG; return 0; }'
	_1 'case $1 in'
	_2 'unknown) set "Unrecognized option: $2" "$@" ;;'
	_2 'noarg) set "Does not allow an argument: $2" "$@" ;;'
	_2 'required) set "Requires an argument: $2" "$@" ;;'
	_2 'pattern:*) set "Does not match the pattern (${1#*:}): $2" "$@" ;;'
	_2 'notcmd) set "Not a command: $2" "$@" ;;'
	_2 '*) set "Validation error ($1): $2" "$@"'
	_1 'esac'
	[ "$_error" ] && _1 "$_error" '"$@" >&2 || exit $?'
	_1 'echo "$1" >&2'
	_1 'exit 1'
	_0 '}'

	[ "$_help" ] && eval "shift 2; getoptions_help $1 $_help" ${3+'"$@"'}
	[ "$_def" ] && _0 "eval $_def \${1+'\"\$@\"'}; eval set -- \"\${$_rest}\""
	_0 '# Do not execute' # exit 1
}
# [getoptions_abbr] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
# shellcheck disable=SC2016,SC2154
getoptions_abbr() {
	abbr() {
		_3 "case '$1' in"
		_4 '"$1") OPTARG=; break ;;'
		_4 '$1*) OPTARG="$OPTARG '"$1"'"'
		_3 'esac'
	}
	args() {
		abbr=1
		shift
		for i; do
			case $i in
				--) break ;;
				[!-+]*) eval "${i%%:*}=\${i#*:}"
			esac
		done
		[ "$abbr" ] || return 0

		for i; do
			case $i in
				--) break ;;
				--\{no-\}*) abbr "--${i#--\{no-\}}"; abbr "--no-${i#--\{no-\}}" ;;
				--*) abbr "$i"
			esac
		done
	}
	setup() { :; }
	for i in flag param option disp; do
		eval "_$i()" '{ args "$@"; }'
	done
	msg() { :; }
	_2 'set -- "${1%%\=*}" "${1#*\=}" "$@"'
	[ "$_alt" ] && _2 'case $1 in -[!-]?*) set -- "-$@"; esac'
	_2 'while [ ${#1} -gt 2 ]; do'
	_3 'case $1 in (*[!a-zA-Z0-9_-]*) break; esac'
	"$@"
	_3 'break'
	_2 'done'
	_2 'case ${OPTARG# } in'
	_3 '*\ *)'
	_4 'eval "set -- $OPTARG $1 $OPTARG"'
	_4 'OPTIND=$((($#+1)/2)) OPTARG=$1; shift'
	_4 'while [ $# -gt "$OPTIND" ]; do OPTARG="$OPTARG, $1"; shift; done'
	_4 'set "Ambiguous option: $1 (could be $OPTARG)" ambiguous "$@"'
	[ "$_error" ] && _4 "$_error" '"$@" >&2 || exit $?'
	_4 'echo "$1" >&2'
	_4 'exit 1 ;;'
	_3 '?*)'
	_4 '[ "$2" = "$3" ] || OPTARG="$OPTARG=$2"'
	_4 "shift 3; eval 'set -- \"\${OPTARG# }\"' \${1+'\"\$@\"'}; OPTARG= ;;"
	_3 '*) shift 2'
	_2 'esac'
}
# [getoptions_help] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
getoptions_help() {
	_width='30,12' _plus='' _leading='  '

	pad() { p=$2; while [ ${#p} -lt "$3" ]; do p="$p "; done; eval "$1=\$p"; }
	kv() { eval "${2-}${1%%:*}=\${1#*:}"; }
	sw() { pad sw "$sw${sw:+, }" "$1"; sw="$sw$2"; }

	args() {
		_type=$1 var=${2%% *} sw='' label='' hidden='' && shift 2
		while [ $# -gt 0 ] && i=$1 && shift && [ "$i" != -- ]; do
			case $i in
				--*) sw $((${_plus:+4}+4)) "$i" ;;
				-?) sw 0 "$i" ;;
				+?) [ ! "$_plus" ] || sw 4 "$i" ;;
				*) [ "$_type" = setup ] && kv "$i" _; kv "$i"
			esac
		done
		[ "$hidden" ] && return 0 || len=${_width%,*}

		[ "$label" ] || case $_type in
			setup | msg) label='' len=0 ;;
			flag | disp) label="$sw " ;;
			param) label="$sw $var " ;;
			option) label="${sw}[=$var] "
		esac
		[ "$_type" = cmd ] && label=${label:-$var } len=${_width#*,}
		pad label "${label:+$_leading}$label" "$len"
		[ ${#label} -le "$len" ] && [ $# -gt 0 ] && label="$label$1" && shift
		echo "$label"
		pad label '' "$len"
		for i; do echo "$label$i"; done
	}

	for i in setup flag param option disp 'msg -' cmd; do
		eval "${i% *}() { args $i \"\$@\"; }"
	done

	echo "$2() {"
	echo "cat<<'GETOPTIONSHERE'"
	"$@"
	echo "GETOPTIONSHERE"
	echo "}"
}
########## END library getoptions.bash ###########


########## START library bashtdlib.bash ###########
#!/usr/bin/env bash

########## START library getoptions.bash ###########
# [getoptions] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
# shellcheck disable=SC2016
getoptions() {
	_error='' _on=1 _no='' _export='' _plus='' _mode='' _alt='' _rest='' _def=''
	_flags='' _nflags='' _opts='' _help='' _abbr='' _cmds='' _init=@empty IFS=' '
	[ $# -lt 2 ] && set -- "${1:?No parser definition}" -
	[ "$2" = - ] && _def=getoptions_parse

	i='					'
	while eval "_${#i}() { echo \"$i\$@\"; }"; [ "$i" ]; do i=${i#?}; done

	quote() {
		q="$2'" r=''
		while [ "$q" ]; do r="$r${q%%\'*}'\''" && q=${q#*\'}; done
		q="'${r%????}'" && q=${q#\'\'} && q=${q%\'\'}
		eval "$1=\${q:-\"''\"}"
	}
	code() {
		[ "${1#:}" = "$1" ] && c=3 || c=4
		eval "[ ! \${$c:+x} ] || $2 \"\$$c\""
	}
	sw() { sw="$sw${sw:+|}$1"; }
	kv() { eval "${2-}${1%%:*}=\${1#*:}"; }
	loop() { [ $# -gt 1 ] && [ "$2" != -- ]; }

	invoke() { eval '"_$@"'; }
	prehook() { invoke "$@"; }
	for i in setup flag param option disp msg; do
		eval "$i() { prehook $i \"\$@\"; }"
	done

	args() {
		on=$_on no=$_no export=$_export init=$_init _hasarg=$1 && shift
		while loop "$@" && shift; do
			case $1 in
				-?) [ "$_hasarg" ] && _opts="$_opts${1#-}" || _flags="$_flags${1#-}" ;;
				+?) _plus=1 _nflags="$_nflags${1#+}" ;;
				[!-+]*) kv "$1"
			esac
		done
	}
	defvar() {
		case $init in
			@none) : ;;
			@export) code "$1" _0 "export $1" ;;
			@empty) code "$1" _0 "${export:+export }$1=''" ;;
			@unset) code "$1" _0 "unset $1 ||:" "unset OPTARG ||:; ${1#:}" ;;
			*)
				case $init in @*) eval "init=\"=\${${init#@}}\""; esac
				case $init in [!=]*) _0 "$init"; return 0; esac
				quote init "${init#=}"
				code "$1" _0 "${export:+export }$1=$init" "OPTARG=$init; ${1#:}"
		esac
	}
	_setup() {
		[ "${1#-}" ] && _rest=$1
		while loop "$@" && shift; do kv "$1" _; done
	}
	_flag() { args '' "$@"; defvar "$@"; }
	_param() { args 1 "$@"; defvar "$@"; }
	_option() { args 1 "$@"; defvar "$@"; }
	_disp() { args '' "$@"; }
	_msg() { args '' _ "$@"; }

	cmd() { _mode=@ _cmds="$_cmds${_cmds:+|}'$1'"; }
	"$@"
	cmd() { :; }
	_0 "${_rest:?}=''"

	_0 "${_def:-$2}() {"
	_1 'OPTIND=$(($#+1))'
	_1 'while OPTARG= && [ $# -gt 0 ]; do'
	[ "$_abbr" ] && getoptions_abbr "$@"

	args() {
		sw='' validate='' pattern='' counter='' on=$_on no=$_no export=$_export
		while loop "$@" && shift; do
			case $1 in
				--\{no-\}*) i=${1#--?no-?}; sw "'--$i'|'--no-$i'" ;;
				--with\{out\}-*) i=${1#--*-}; sw "'--with-$i'|'--without-$i'" ;;
				[-+]? | --*) sw "'$1'" ;;
				*) kv "$1"
			esac
		done
		quote on "$on"
		quote no "$no"
	}
	setup() { :; }
	_flag() {
		args "$@"
		[ "$counter" ] && on=1 no=-1 v="\$((\${$1:-0}+\$OPTARG))" || v=''
		_3 "$sw)"
		_4 '[ "${OPTARG:-}" ] && OPTARG=${OPTARG#*\=} && set "noarg" "$1" && break'
		_4 "eval '[ \${OPTARG+x} ] &&:' && OPTARG=$on || OPTARG=$no"
		valid "$1" "${v:-\$OPTARG}"
		_4 ';;'
	}
	_param() {
		args "$@"
		_3 "$sw)"
		_4 '[ $# -le 1 ] && set "required" "$1" && break'
		_4 'OPTARG=$2'
		valid "$1" '$OPTARG'
		_4 'shift ;;'
	}
	_option() {
		args "$@"
		_3 "$sw)"
		_4 'set -- "$1" "$@"'
		_4 '[ ${OPTARG+x} ] && {'
		_5 'case $1 in --no-*|--without-*) set "noarg" "${1%%\=*}"; break; esac'
		_5 '[ "${OPTARG:-}" ] && { shift; OPTARG=$2; } ||' "OPTARG=$on"
		_4 "} || OPTARG=$no"
		valid "$1" '$OPTARG'
		_4 'shift ;;'
	}
	valid() {
		set -- "$validate" "$pattern" "$1" "$2"
		[ "$1" ] && _4 "$1 || { set -- ${1%% *}:\$? \"\$1\" $1; break; }"
		[ "$2" ] && {
			_4 "case \$OPTARG in $2) ;;"
			_5 '*) set "pattern:'"$2"'" "$1"; break'
			_4 "esac"
		}
		code "$3" _4 "${export:+export }$3=\"$4\"" "${3#:}"
	}
	_disp() {
		args "$@"
		_3 "$sw)"
		code "$1" _4 "echo \"\${$1}\"" "${1#:}"
		_4 'exit 0 ;;'
	}
	_msg() { :; }

	[ "$_alt" ] && _2 'case $1 in -[!-]?*) set -- "-$@"; esac'
	_2 'case $1 in'
	_wa() { _4 "eval 'set -- $1' \${1+'\"\$@\"'}"; }
	_op() {
		_3 "$1) OPTARG=\$1; shift"
		_wa '"${OPTARG%"${OPTARG#??}"}" '"$2"'"${OPTARG#??}"'
		_4 "$3"
	}
	_3 '--?*=*) OPTARG=$1; shift'
	_wa '"${OPTARG%%\=*}" "${OPTARG#*\=}"'
	_4 ';;'
	_3 '--no-*|--without-*) unset OPTARG ;;'
	[ "$_alt" ] || {
		[ "$_opts" ] && _op "-[$_opts]?*" '' ';;'
		[ ! "$_flags" ] || _op "-[$_flags]?*" - 'OPTARG= ;;'
	}
	[ "$_plus" ] && {
		[ "$_nflags" ] && _op "+[$_nflags]?*" + 'unset OPTARG ;;'
		_3 '+*) unset OPTARG ;;'
	}
	_2 'esac'
	_2 'case $1 in'
	"$@"
	rest() {
		_4 'while [ $# -gt 0 ]; do'
		_5 "$_rest=\"\${$_rest}" '\"\${$(($OPTIND-$#))}\""'
		_5 'shift'
		_4 'done'
		_4 'break ;;'
	}
	_3 '--)'
	[ "$_mode" = @ ] || _4 'shift'
	rest
	_3 "[-${_plus:++}]?*)" 'set "unknown" "$1"; break ;;'
	_3 '*)'
	case $_mode in
		@)
			_4 "case \$1 in ${_cmds:-*}) ;;"
			_5 '*) set "notcmd" "$1"; break'
			_4 'esac'
			rest ;;
		+) rest ;;
		*) _4 "$_rest=\"\${$_rest}" '\"\${$(($OPTIND-$#))}\""'
	esac
	_2 'esac'
	_2 'shift'
	_1 'done'
	_1 '[ $# -eq 0 ] && { OPTIND=1; unset OPTARG; return 0; }'
	_1 'case $1 in'
	_2 'unknown) set "Unrecognized option: $2" "$@" ;;'
	_2 'noarg) set "Does not allow an argument: $2" "$@" ;;'
	_2 'required) set "Requires an argument: $2" "$@" ;;'
	_2 'pattern:*) set "Does not match the pattern (${1#*:}): $2" "$@" ;;'
	_2 'notcmd) set "Not a command: $2" "$@" ;;'
	_2 '*) set "Validation error ($1): $2" "$@"'
	_1 'esac'
	[ "$_error" ] && _1 "$_error" '"$@" >&2 || exit $?'
	_1 'echo "$1" >&2'
	_1 'exit 1'
	_0 '}'

	[ "$_help" ] && eval "shift 2; getoptions_help $1 $_help" ${3+'"$@"'}
	[ "$_def" ] && _0 "eval $_def \${1+'\"\$@\"'}; eval set -- \"\${$_rest}\""
	_0 '# Do not execute' # exit 1
}
export -f getoptions

# [getoptions_abbr] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
# shellcheck disable=SC2016,SC2154
getoptions_abbr() {
	abbr() {
		_3 "case '$1' in"
		_4 '"$1") OPTARG=; break ;;'
		_4 '$1*) OPTARG="$OPTARG '"$1"'"'
		_3 'esac'
	}
	args() {
		abbr=1
		shift
		for i; do
			case $i in
				--) break ;;
				[!-+]*) eval "${i%%:*}=\${i#*:}"
			esac
		done
		[ "$abbr" ] || return 0

		for i; do
			case $i in
				--) break ;;
				--\{no-\}*) abbr "--${i#--\{no-\}}"; abbr "--no-${i#--\{no-\}}" ;;
				--*) abbr "$i"
			esac
		done
	}
	setup() { :; }
	for i in flag param option disp; do
		eval "_$i()" '{ args "$@"; }'
	done
	msg() { :; }
	_2 'set -- "${1%%\=*}" "${1#*\=}" "$@"'
	[ "$_alt" ] && _2 'case $1 in -[!-]?*) set -- "-$@"; esac'
	_2 'while [ ${#1} -gt 2 ]; do'
	_3 'case $1 in (*[!a-zA-Z0-9_-]*) break; esac'
	"$@"
	_3 'break'
	_2 'done'
	_2 'case ${OPTARG# } in'
	_3 '*\ *)'
	_4 'eval "set -- $OPTARG $1 $OPTARG"'
	_4 'OPTIND=$((($#+1)/2)) OPTARG=$1; shift'
	_4 'while [ $# -gt "$OPTIND" ]; do OPTARG="$OPTARG, $1"; shift; done'
	_4 'set "Ambiguous option: $1 (could be $OPTARG)" ambiguous "$@"'
	[ "$_error" ] && _4 "$_error" '"$@" >&2 || exit $?'
	_4 'echo "$1" >&2'
	_4 'exit 1 ;;'
	_3 '?*)'
	_4 '[ "$2" = "$3" ] || OPTARG="$OPTARG=$2"'
	_4 "shift 3; eval 'set -- \"\${OPTARG# }\"' \${1+'\"\$@\"'}; OPTARG= ;;"
	_3 '*) shift 2'
	_2 'esac'
}
export -f getoptions_abbr

# [getoptions_help] License: Creative Commons Zero v1.0 Universal
# https://github.com/ko1nksm/getoptions (v3.3.0)
getoptions_help() {
	_width='30,12' _plus='' _leading='  '

	pad() { p=$2; while [ ${#p} -lt "$3" ]; do p="$p "; done; eval "$1=\$p"; }
	kv() { eval "${2-}${1%%:*}=\${1#*:}"; }
	sw() { pad sw "$sw${sw:+, }" "$1"; sw="$sw$2"; }

	args() {
		_type=$1 var=${2%% *} sw='' label='' hidden='' && shift 2
		while [ $# -gt 0 ] && i=$1 && shift && [ "$i" != -- ]; do
			case $i in
				--*) sw $((${_plus:+4}+4)) "$i" ;;
				-?) sw 0 "$i" ;;
				+?) [ ! "$_plus" ] || sw 4 "$i" ;;
				*) [ "$_type" = setup ] && kv "$i" _; kv "$i"
			esac
		done
		[ "$hidden" ] && return 0 || len=${_width%,*}

		[ "$label" ] || case $_type in
			setup | msg) label='' len=0 ;;
			flag | disp) label="$sw " ;;
			param) label="$sw $var " ;;
			option) label="${sw}[=$var] "
		esac
		[ "$_type" = cmd ] && label=${label:-$var } len=${_width#*,}
		pad label "${label:+$_leading}$label" "$len"
		[ ${#label} -le "$len" ] && [ $# -gt 0 ] && label="$label$1" && shift
		echo "$label"
		pad label '' "$len"
		for i; do echo "$label$i"; done
	}

	for i in setup flag param option disp 'msg -' cmd; do
		eval "${i% *}() { args $i \"\$@\"; }"
	done

	echo "$2() {"
	echo "cat<<'GETOPTIONSHERE'"
	"$@"
	echo "GETOPTIONSHERE"
	echo "}"
}
export -f getoptions_help
########## END library getoptions.bash ###########


# Prints an error message to stderr
# Input:
#     message : The message to print to stderr
bashtdlib:error_message() {
  local message
  message="$1"
  if [[ -z "$message" ]]; then
    echo "ERROR: function ${FUNCNAME[1]}()" >&2
  else
    echo "ERROR: function ${FUNCNAME[1]}(): $message" >&2
  fi
}
export -f bashtdlib:error_message

# Prints an error message to stderr
# and exits with status code 1
# Input:
#     message : The message to print to stderr
bashtdlib:error_exit() {
	local message
	message="$1"
	echo "FATAL: function ${FUNCNAME[1]}(): $message. Exiting"
	exit 1
}
export -f bashtdlib:error_exit

# Receives the name of a variable, an integer n, and a list of arguments
# It stores the nth value from the list of arguments in the variable
# whose name it received
# Example:
#     func() {
#       local arg1
#       local arg2
#       bashtdlib:store_arg arg1 1 "$@"
#       bashtdlib:store_arg arg2 2 "$@"
#       echo "received arg1=$arg1 and arg2=$arg2"
#     }
# Input:
#   variable_name : Name of variable to store value in
#   n             : index in caller_args list whose value will be stored
#   caller_args   : List of arguments received by caller function
# Output:
#   exit_status:
#       1 if an error ocurred
#       0 otherwise
#   stdout:
#       nothing
#   stderr:
#       error message if an error ocurred
bashtdlib:store_arg() {
	local variable_name
	local argument_num
	variable_name="$1"
	argument_num="$2"
	shift 2

  if [[ "${#}" = "0" ]]; then
    bashtdlib:error_message "arguments of function ${FUNCNAME[1]} were not provided or were empty"
    return 1 
  fi

	if [[ -z "$variable_name" ]]; then
		bashtdlib:error_message "No value was provided for variable_name"
    return 1
	fi

	if [[ -z "$argument_num" ]]; then
		bashtdlib:error_message "No value was provided for [$variable_name] (argument $argument_num) but is r  equired"
		return 1
	fi

	declare -n variable_name

	## she#llcheck disable=SC2034
	variable_name="${!argument_num}"
}
export -f bashtdlib:store_arg

# Takes a message and a command with all its arguments and runs it
# It will immediately exit the script with status 1 and it will print to stderr
# anything the command printed, along with the message given as input
# if at least one of the following conditions are met:
#   - The executed command returned an exit status of 1 AND
#     it printed something to stderr
#   - The executed command returned neither 0 nor 1
# If none of these conditions are met, it will return the exit status
# of the executed command (be it 1 or 0)
# This function is useful for error checking commands run as part of a condition
# Usage:
#     exit_on_error [options...] [arguments...]
# Options:
#   -s, --skip-if-contains  STRING ignore error condition if the error contains this string 
# Arguments:
#    1. message : the message to print when exiting
#    2-n        : the command to run with all its arguments
# Example:
#   # In the following snippet, if the command some_command errors out
#   # bashtdlib:exit_on_error will catch it and exit the script instead of
#   # treating the exit code as a false value and continuing after the condition
#   if bashtdlib:exit_on_error some_command; then
#       do_something
#   this_command_will_not_execute
# Output:
#     exit status:
#         1 and exit script if the command errored out
#         otherwise, whatever the command's exit status was (1 or 0)
#     stdout:
#         nothing
#     stderr:
#         error message provided as message argument
bashtdlib:exit_on_error() {

  # Parse options
  local skip_string 
  local rest
  bashtdlib:exit_on_error:parser_def() {
    setup rest help:usage
    param skip_string -s --skip-if-contains init:"=" -- "ignore error condition if the error message contains this string"
  }
  eval "$(getoptions bashtdlib:exit_on_error:parser_def bashtdlib:exit_on_error:parse)" 
  bashtdlib:exit_on_error:parse "$@"
  eval "set -- $rest"

  # Check if errexit is enabled
  local errexit_was_enabled
  [[ -o errexit ]] && errexit_was_enabled="true"

  # Disable errexit if it was enabled
  [[ -n "$errexit_was_enabled" ]] && set +e

  # Check if xtrace is enabled
  local xtrace_was_enabled
  [[ -o xtrace ]] && xtrace_was_enabled="true"

  # Disable xtrace if it was enabled
  [[ -n "$xtrace_was_enabled" ]] && set +x


	local message="$1"
	shift 1
	local stderr_file
	stderr_file="$(mktemp)"
	local exit_status
	"$@" 2>"$stderr_file"  
	exit_status="$?"

  # if the executed command returned an exit status of 1 AND
  # it printed somethine to stderr
  if [[ "$exit_status" != "0" ]]; then
    if [[ "$exit_status" = "1" ]] && [[ -s "$stderr_file" ]]; then
      # if skip_string was NOT empty and skip string was found in the stderr message
      if [[ -z "$skip_string" ]] || ! grep -q "$skip_string" "$stderr_file"; then
        bashtdlib:error_exit "$message. Error: $(cat "$stderr_file")"
      fi
    fi

    # if the executed command returned a non-0 or non-1 exit status
    if [[ "$exit_status" != 1 ]]; then
      # if skip_string was NOT empty and skip string was found in the stderr message
      if [[ -z "$skip_string" ]] || ! grep -q "$skip_string" "$stderr_file"; then
        bashtdlib:error_exit "$message. Error: $(cat "$stderr_file")"
      fi
    fi
  fi
	return "$exit_status"
  
  # Reenable errexit if it was disabled
  [[ -n "$errexit_was_enabled" ]] && set -e

  # Reenable xtrace if it was disabled
  [[ -n "$xtrace_was_enabled" ]] && set -x
}
export -f bashtdlib:exit_on_error

# Returns 0 if the given command is available in the path
# Returns 1 otherwise
# Inputs:
#     1. command: command to check
#     2. message (optional): an optional message with instructions for installing the command 
# Outputs:
#   exit_status:
#       0 if command is available
#       1 if command is not available 
#   stdout:
#       nothing
#   stderr:
#       error message if argument parsing failed
#       (TODO) error message if 'command' command is not available
bashtdlib:is_command_available() {
  local _command
  bashtdlib:store_arg _command 1 "$@" || return 1
  if ! command -v "$_command" >/dev/null 2>&1 ; then
    return 1 
  fi
  return 0
}
export -f bashtdlib:is_command_available

# Returns 0 if the current user is root 
# Returns 1 otherwise
# Inputs:
#     None
# Outputs:
#   exit_status:
#       0 if user is root
#       1 if user is not root
#       2 if an error ocurred
#   stdout:
#       nothing
#   stderr:
#       error message if command is not available
bashtdlib:am_i_root() {
  local base_error_msg
  local uid
  base_error_msg="Unable to determine if current user is root"
  bashtdlib:is_command_available "id" || error_return "$base_error_msg: command 'id' is unavailable"
  uid="$(id -u)" 
  [[ "$uid" = "0" ]] || return 1
}
export -f bashtdlib:am_i_root

# Runs the given arguments as a command
# and appends "sudo" to the command list if
# the user is not root.
# Usage: sudo_if_not_root [options...] [arguments...]
# Options:
#   -p, --password PASSWORD password to use with sudo
# Arguments:
#     1-n: command to execute with its arguments
# Example:
#     sudo_if_not_root apt-get update
#     # If the current user is root, this will expand to:
#     apt-get update
#     # If the current user is not root, this will expand to:
#     sudo apt-get update
# Outputs:
#   exit_status:
#       2 if an error ocurred
#       0 otherwise
#   stdout:
#       nothing
#   stderr:
#       error message if an error ocurred
bashtdlib:sudo_if_not_root() {
  local password
  local rest
  bashtdlib:sudo_if_not_root:parser_def() {
    setup rest help:usage
    param password -p --password init:"= " -- "password to use with sudo. Will be ignored if user is root"
  }
  eval "$(getoptions bashtdlib:sudo_if_not_root:parser_def bashtdlib:sudo_if_not_root:parse)" 
  bashtdlib:sudo_if_not_root:parse "$@"
  eval "set -- $rest"
  bashtdlib:is_command_available "sudo" || bashtdlib:error_exit "Command 'sudo' is not available. You can install it by running the following command as a root user: apt-get update && apt-get install sudo" 
  if bashtdlib:exit_on_error "Unable to determine if current user is root" bashtdlib:am_i_root; then
    "$@" 
  else
   echo "$password" | sudo -S "$@"
  fi
}
export -f bashtdlib:sudo_if_not_root

########## END library bashtdlib.bash ###########


does_user_exist() {
  local user
  bashtdlib:store_arg user 1
  if ! id "$user" >&1 >/dev/null; then
    return 1
  fi
}

parser_definition() {
        setup   REST help:usage \
                -- "Usage: ${2##*/} [options...] [arguments...]" ''
        msg -- 'Options:'
        param   USERNAME    -u    --user init:"=vagrant"  -- "Custom user to user for Vagrant access"
        param   PASSWORD    -p    --password init:"= "  -- "password for custom user. Will be ignored unless --user is also set"
        disp    :usage  -h    --help
        disp    VERSION       --version
}

eval "$(getoptions parser_definition parse "$0") exit 1"
parse "$@"
eval "set -- $REST"

export DEBIAN_FRONTEND=noninteractive


# Steps taken from: https://github.com/rofrano/vagrant-docker-provider/blob/master/Dockerfile.ubuntu
# Install packages needed for SSH and interactive OS
bashtdlib:exit_on_error -- "Unable to run apt-get update" bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get -y update
# Install apt-utils
bashtdlib:exit_on_error -- "Unable to install apt-utils" bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get install -y apt-utils
bashtdlib:exit_on_error --skip-if-contains='dpkg-query: error: --search needs at least one file name pattern argument' -- 'Unable to unminimize' bashtdlib:sudo_if_not_root --password="$PASSWORD" -- bash -c 'set -o pipefail; yes | DEBIAN_FRONTEND=noninteractive unminimize'
bashtdlib:exit_on_error -- 'Unable to install packages' bashtdlib:sudo_if_not_root --password="$PASSWORD" -- apt-get -y install \
		openssh-server \
		passwd \
		man-db \
		sudo \
		wget \
		vim-tiny 
echo "Installed packages!!!!!!!!!!"
bashtdlib:exit_on_error -- "Unable to run apt-get" apt-get -qq clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable systemd (from Matthew Warman's mcwarman/vagrant-provider)
# TODO: Figure out why this line only runs in sh but not bash
/bin/sh -c '(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done)'
rm -f /lib/systemd/system/multi-user.target.wants/*
rm -f /etc/systemd/system/*.wants/*
rm -f /lib/systemd/system/local-fs.target.wants/*
rm -f /lib/systemd/system/sockets.target.wants/*udev*
rm -f /lib/systemd/system/sockets.target.wants/*initctl*
rm -f /lib/systemd/system/basic.target.wants/*
rm -f /lib/systemd/system/anaconda.target.wants/*

# Enable ssh for vagrant
systemctl enable ssh.service

# Create the vagrant user
if ! does_user_exist "$USERNAME"; then
  useradd -m -G sudo -s /bin/bash "$USERNAME" 
fi
echo "$USERNAME:vagrant" | sudo chpasswd
bash -c "echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant"
chmod 440 /etc/sudoers.d/vagrant

# Establish ssh keys for vagrant
mkdir -p "/home/$USERNAME/.ssh"
chmod 700 "/home/$USERNAME/.ssh"
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O "/home/$USERNAME/.ssh/authorized_keys"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
