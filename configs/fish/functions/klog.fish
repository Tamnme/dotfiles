function klog --description 'kubectl logs <pod> | hl'
    for tool in kubectl hl
        if not command -q $tool
            echo "klog: missing $tool (brew install $tool)" >&2
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

    argparse 'n/namespace=' 'f/follow' 'c/container=' 's/since=' 'p/previous' -- $k_argv
    or return 2

    set -l pod $argv[1]
    if test -z "$pod"
        echo "klog: usage: klog POD [-n NS] [-f] [-c CON] [-s SINCE] [-p] [-- HL_ARGS...]" >&2
        return 2
    end

    set -l k_cmd logs $pod
    test -n "$_flag_namespace"; and set -a k_cmd -n $_flag_namespace
    test -n "$_flag_container"; and set -a k_cmd -c $_flag_container
    set -q _flag_previous; and set -a k_cmd --previous

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
