function logv --description 'view log files / stdin via hl'
    if not command -q hl
        echo "logv: missing hl (brew install hl)" >&2
        return 127
    end

    set -l hl_args
    set -l files $argv
    set -l idx (contains -i -- -- $argv)
    if test -n "$idx"
        if test $idx -gt 1
            set files $argv[1..(math $idx - 1)]
        else
            set files
        end
        if test $idx -lt (count $argv)
            set hl_args $argv[(math $idx + 1)..]
        end
    end

    set -l pager_args
    if isatty stdout
        if not contains -- -f $hl_args; and not contains -- --follow $hl_args
            set pager_args -P
        end
    end

    if test (count $files) -gt 0
        hl $pager_args $hl_args $files
    else
        hl $pager_args $hl_args
    end
end
