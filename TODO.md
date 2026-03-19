# TODO

- consolidate mene->profile with profile button on top right on main screen
- show one beer price, how to get it for each user if they are consuming in different volumes. Mabe use 0,5l or adequate for imperial units.
- keg session screen - put Keg level and My stats into one Card
- show list of participants as list of rows, with name, beer count, last pour time, estimated BAC and button to "pour for"
- My stats - show time instantly - 1sec update
- settings - language, currency, decimal dot/comma, litres/pounds/pints,
- extend keg states - record created and keg is ready for tap, keg is tapped and active, keg is nuptapped but unfinished, keg is done
- move Past sessions to separate screen, accesible from menu
- when the keg is done (Keg empty) screen add tip for the user to pay for the app by sending money for beer to Revolut by following this link: revolut.me/hnyko
- when the keg is done do the final calculation, count the keg volume as a sum of all users consumption (can be less or even more than initial volume of keg) count price for each user based on his ration of consuption. Show sum of users consuptions and their spending.
- implement joining accounts/bills, show groupped users in participants list, calculate consumption of group, but keep consuption of each member of group, everyone can create group and can join any existig group. Groups are per keg session. User can be only in one group, user can create only one group. User can be without group - alone.
- calculate and show the BAC, to the update on each new beer and do the counting during time (each second?). Calculate and show the estimation when BAC will be 0 (ready to drive). Show other participants BAC in participants list
- implemet notifications (even if the app is not running). If someone do the pour on behalf, when keg is done, when your estimated BAC is 0, all those notification can be enabled/disabled in user settings
- when the user slows down in consuption (based on average consumption speed) send notification, also will be configurable to enable/disable
- Review the bill split - show whole bill, all participatn's consumption, groups consuption, keg owner has possibility to add/remove beers to anyone. Prices and total consumed volume will be recalculated.
- disable settle-up export for now - just comment out
- clean the code - check if all supporting functions (countig) is defined only once
- use same logic for popouts (Clicking "I got beer" leads to different toast, which is not dissapearing than "Pour for ..." which is dissapearing, but unable to do "undo")
- About screen: change icon to logo, add note about possibility to donate beer to the author via Revolut by following this link: revolut.me/hnyko. Implement Privacy policy. Update showLicensePage. Add https://responsibledrinking.eu/. Add Card: If you are using this app often, consider visiting: https://www.addictioncenter.com/addiction/addiction-in-the-eu/.
- create tests using https://github.com/flutter/flutter/tree/main/packages/integration_test
- keg session owner can create users manually (those users will be used if users cant join via their account and application). When user join the session and there are those manually created users, user can (but not neccesary) choose one of them to join and merge with this user. 

- think what could be added as a additional features or logic
