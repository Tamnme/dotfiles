-- Banner sender AND click target for the daily lesson.
--
-- macOS attributes a notification to the process that posted it, and clicking
-- a banner activates that process. `osascript -e 'display notification'` is
-- therefore a dead end: it posts as Script Editor, so the click opens Script
-- Editor. Posting from this applet instead makes the click land here, and here
-- we open the lesson.
--
--   Lesson.app --notify "<subtitle>"   posts the banner, then waits
--   (click the banner)                 -> reopen -> browser
--
-- Stays open via `on idle` so it is still alive to receive the click; it quits
-- itself after an hour so a missed lesson doesn't leave a process lying around.

property lessonURL : "http://127.0.0.1:7331/"
property launchedAt : 0

on openLesson()
	do shell script "/usr/bin/open " & quoted form of lessonURL
end openLesson

on trace(msg)
	do shell script "echo " & quoted form of (msg as text) & " >> /tmp/lesson-notify.log"
end trace

on run argv
	set launchedAt to current date
	trace("run argc=" & (count of argv) & " argv=" & (argv as text))
	if (count of argv) > 0 and item 1 of argv is "--notify" then
		set sub to ""
		if (count of argv) > 1 then set sub to item 2 of argv
		trace("posting notification")
		display notification sub with title "📚 Lesson ready" subtitle "click to open" sound name "Glass"
		trace("posted without error")
	else
		-- Launched by hand, not to notify: just show the lesson.
		openLesson()
	end if
end run

on reopen
	-- Fired when the banner is clicked while the applet is still running.
	openLesson()
end reopen

on idle
	if launchedAt is not 0 and ((current date) - launchedAt) > 3600 then quit
	return 60
end idle
