- after creating keg session, then in three dot menu there is "Edit session" which doesnt work. And after clicking "Delete session" and confirming then empty page is shown with "Session not found" and unable to navigate anywhere, after deleting it should redirect to home screen.
- system "back" key or swipe to go back close the app, should follow the screens af if user is on eg. keg detail, it should go back to keg session and the to home screen
- when user click "I got beer" pop out is showed ("Pour logged!") but this pop not dissapear, should behave same way as "Poured for ondyn!" pop.
- when editting user profile, prefill inputs with current values if they exists
- "past sessions" screens not loading properly, there is flutter error: W/Firestore(30012): (26.1.0) [Firestore]: Listen for QueryWrapper(query=Query(target=Query(kegSessions where status==done order by __name__);limitType=LIMIT_TO_FIRST)) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
- add alcohol drinked/remaining in the keg level/stats card. Add alcohol drunk by user in "My stats". Alcohol will be calculated from keg volume and beer Alcohol content.
- currency annd decimal point is not respected when creating new keg session and in keg level/stats and "My stats"
- beers count in participants list - add one decimal point. When user is drinking eg. 0.3l volumes, the whole number is missleading
- "0.5l beer" price: put it on the right next to keg status in "Keg level" section
- when screen is updated (eg someone else pour the beer) than page is scrolled to top. Keep the scroll where the user was before update.
- enable users to choose avatar, also enable avatar for joint Accounts, when group is created.
- consolidate participants and accounts details - to participants detail add consumed price. To Accounts add icon of beer and beer count
- when keg done, show statistics - participatns, accounts, total keg time (from tap to done)
- SKIP FOR NOW, need clarification: "Make keg done" can be executed only by keg session creator. other users should have this menu option not visible and cant finish the keg
- review the BAC calculation, one 0,5l 10° beer should be approx 0,2 promile, based on info from internet. https://drunkcalc.com/#step-one, https://www.calculator.net/bac-calculator.html
- when another user do the update on keg session detial (pour a beer) then for other users sestion with participants blink as it is reloading and shortly shows loading circle. Update the participants on background and avoid showing loading ring when change happenns.
- ALREADY IMPLEMENTED: enable tonchange BAC visibility and statistic visibility even during keg session, not only when joining session
- add detail view after clicking on participant in the list - show same as for "My stats" and add graph of consumtion beer volume vs time, BAC vs time 
- put information from "Est. BAC:" card into My stats. Add car icon for time to drive. Remove "Please drink responsibly" add warning that it is an estimation - short note, but clear and visible.
- zero BAC estimation. Keep one second update on user app, but reduce calculation at "cloud functions" to 20min to reduce paid cloud functions load
- notificattion icon in android's status bar and in notification itself is just white circle, should be the logo
- notification for "Ready to drive!" BAC=0 is sent twice
- check the app name where it is visible for user at screens and make sure everywhere it is "Beerer", not "BeerEr"



- cleanup: DB will be cleared, rething about all names, database attributes, screen names, variables if it makes sense. Rename accordingly. Analyze code, if something is repeating put it into shared code. Make sure all graphics types useses same dimensions, colors and theme everywhere.
