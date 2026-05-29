function zreset --description "Kill + delete all zellij sessions (restart ritual)"
    set -l sessions (zellij list-sessions -s -n 2>/dev/null)
    if test -z "$sessions"
        echo "No sessions."
        return 0
    end

    echo "Sessions:"
    for s in $sessions
        echo "  $s"
    end

    read -P "Kill + delete all? [y/N] " ans
    if test "$ans" != y -a "$ans" != Y
        echo "Aborted."
        return 1
    end

    zellij kill-all-sessions -y 2>/dev/null
    zellij delete-all-sessions -y 2>/dev/null
    echo "Done. Open ghostty / Zed terminal to start fresh."
end
