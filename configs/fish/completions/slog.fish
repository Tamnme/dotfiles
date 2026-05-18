function __slog_namespaces
    kubectl get ns -o name 2>/dev/null | string replace 'namespace/' ''
end

complete -c slog -f
complete -c slog -s n -l namespace -x -a '(__slog_namespaces)' -d namespace
complete -c slog -s t -l tail -x -a '10 50 100 500 1000' -d tail
