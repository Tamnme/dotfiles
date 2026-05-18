function klogl --description 'kubectl logs -l SELECTOR | hl'
    for tool in kubectl hl
        if not command -q $tool
            echo "klogl: missing $tool" >&2
            return 127
        end
    end

    set -l hl_args
    set -l k_argv $argv
    set -l idx (contains -i -- -- $argv)
    if test -n "$idx"
        if test $idx -gt 1
            set k_argv $argv[1..(math $idx - 1)]
        else
            set k_argv
        end
        if test $idx -lt (count $argv)
            set hl_args $argv[(math $idx + 1)..]
        end
    end

    argparse 'n/namespace=' 'f/follow' 's/since=' -- $k_argv
    or return 2

    set -l sel $argv[1]
    if test -z "$sel"
        echo "klogl: usage: klogl SELECTOR [-n NS] [-f] [-s SINCE] [-- HL_ARGS...]" >&2
        return 2
    end

    set -l k_cmd logs -l $sel --all-containers --max-log-requests=20 --prefix
    test -n "$_flag_namespace"; and set -a k_cmd -n $_flag_namespace

    if set -q _flag_follow
        set -a k_cmd -f
        kubectl $k_cmd | hl $hl_args
    else
        set -l since 10m
        test -n "$_flag_since"; and set since $_flag_since
        set -a k_cmd --since=$since
        kubectl $k_cmd | hl -P $hl_args
    end
end
