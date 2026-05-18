function klogp --description 'fzf pick pod, then klog'
    for tool in kubectl fzf hl
        if not command -q $tool
            echo "klogp: missing $tool" >&2
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

    argparse 'n/namespace=' 'f/follow' -- $k_argv
    or return 2

    set -l ns_args
    test -n "$_flag_namespace"; and set ns_args -n $_flag_namespace

    set -l pod (kubectl get pods $ns_args -o name 2>/dev/null | string replace 'pod/' '' | fzf --height 40% --reverse --prompt='pod> ')
    test -z "$pod"; and return 130

    set -l klog_args $pod
    test -n "$_flag_namespace"; and set -a klog_args -n $_flag_namespace
    set -q _flag_follow; and set -a klog_args -f
    if test (count $hl_args) -gt 0
        set -a klog_args -- $hl_args
    end

    klog $klog_args
end
