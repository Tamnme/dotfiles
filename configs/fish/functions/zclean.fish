function zclean --description "Delete zellij sessions except ghostty + current project"
    set -l keep ghostty
    if test -n "$PWD"
        set -a keep (basename (dirname $PWD))-(basename $PWD)
    end

    set -l sessions (zellij list-sessions -s -n 2>/dev/null)
    if test -z "$sessions"
        echo "No sessions."
        return 0
    end

    for s in $sessions
        if contains -- $s $keep
            echo "keep   $s"
        else
            zellij delete-session $s >/dev/null 2>&1
            and echo "delete $s"
            or echo "fail   $s"
        end
    end
end
