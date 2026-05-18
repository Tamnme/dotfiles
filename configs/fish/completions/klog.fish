function __klog_ns_from_tokens
    set -l tokens (commandline -opc)
    for i in (seq 1 (count $tokens))
        switch $tokens[$i]
            case -n --namespace
                set -l j (math $i + 1)
                if test $j -le (count $tokens)
                    echo $tokens[$j]
                    return
                end
        end
    end
end

function __klog_namespaces
    kubectl get ns -o name 2>/dev/null | string replace 'namespace/' ''
end

function __klog_pods
    set -l ns (__klog_ns_from_tokens)
    if test -n "$ns"
        kubectl get pods -n $ns -o name 2>/dev/null | string replace 'pod/' ''
    else
        kubectl get pods -o name 2>/dev/null | string replace 'pod/' ''
    end
end

function __klog_pod_from_tokens
    set -l tokens (commandline -opc)
    set -l skip 0
    for i in (seq 2 (count $tokens))
        if test $skip -eq 1
            set skip 0
            continue
        end
        set -l t $tokens[$i]
        switch $t
            case -n --namespace -c --container -s --since
                set skip 1
            case '-*'
                # boolean flag
            case '*'
                echo $t
                return
        end
    end
end

function __klog_containers
    set -l pod (__klog_pod_from_tokens)
    test -z "$pod"; and return
    set -l ns (__klog_ns_from_tokens)
    if test -n "$ns"
        kubectl get pod $pod -n $ns -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' '
    else
        kubectl get pod $pod -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' '
    end
end

complete -c klog -f
complete -c klog -n 'not __fish_seen_subcommand_from (__klog_pods)' -a '(__klog_pods)' -d pod
complete -c klog -s n -l namespace -x -a '(__klog_namespaces)' -d namespace
complete -c klog -s c -l container -x -a '(__klog_containers)' -d container
complete -c klog -s f -l follow -d 'follow logs'
complete -c klog -s p -l previous -d 'previous container'
complete -c klog -s s -l since -x -a '30s 1m 5m 10m 30m 1h 6h 24h' -d since
