function slog --description 'stern PATTERN | hl'
    for tool in stern hl
        if not command -q $tool
            echo "slog: missing $tool (stern: brew install stern)" >&2
            return 127
        end
    end

    set -l hl_args
    set -l s_argv $argv
    set -l idx (contains -i -- -- $argv)
    if test -n "$idx"
        if test $idx -gt 1
            set s_argv $argv[1..(math $idx - 1)]
        else
            set s_argv
        end
        if test $idx -lt (count $argv)
            set hl_args $argv[(math $idx + 1)..]
        end
    end

    argparse 'n/namespace=' 't/tail=' -- $s_argv
    or return 2

    set -l pattern $argv[1]
    if test -z "$pattern"
        echo "slog: usage: slog PATTERN [-n NS] [-t N | --tail N] [-- HL_ARGS...]" >&2
        return 2
    end

    set -l tail 50
    test -n "$_flag_tail"; and set tail $_flag_tail

    set -l s_cmd $pattern --tail=$tail --output=json
    test -n "$_flag_namespace"; and set -a s_cmd -n $_flag_namespace

    stern $s_cmd | hl $hl_args
end
