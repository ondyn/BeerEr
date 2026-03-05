Counting beers from a keg at a party


Application description:
- application which will use Google database (probably Firebase), will be available for Android and iOS
- user will create his account (using username/password with mail verification, or using social auth mechanims). Fill nickname, weight, age, male/female.
- any user can set up new keg party - defining volume of keg, beer name, price, alcohol content, predefined beer volumes (like 0,5liter, 0,3 liter,...), date/time of first keg tapping (will be set when user click "tap a keg" in keg details). When creating keg, list of available beers will be taken from https://untappd.com/ API, user can add "free text" input keg if not found on untappd.com
- after creating keg and clicking "tap a keg", user can share information for others to join this keg session. Can share link to join (whatsapp, message, mail, QR code).
- after user will join the session. User will set nickname (predefined from his profile), set visibility of his statistics. Each time user pour a beer he will click "I got beer", user can change the volume (predefined volumes or manually filled, last selection  will be remembered for next time). Beer drinking time will start to measure how long user is drinking one beer.
- statistics: visible all the time showing time of drinkig last beer, time from last beer, average drinking rate, calculating volume of alcohol in blood based on weight and age (calculated on users device). Estimation of remaining volume in keg. Prediction when keg will be empty based on current rate of consuption. Price of consumed beers.
- pause keg - "untap unfinished keg" and later "tap keg" again, in this paused state noone can pour a beer.
- can see other people's statistics unless they explicitly prohibit sharing them
- user can pour beers for others - when pour a beer for someone else, user switch to user list and click "plus" button to add a beer, defining the volume (volume from last pouring will be filled)
- afte keg is empty, any user can click "keg done", keg session will be still visible for users, but noone could add or edit beers except user who created the keg session
- user can see the history of keg sessions
- any number of users can join to joint account/bill (eg. family) and same statistics will be calculated for that account. Others can see list of accounts. Users which not join/create any joint account will be listed as separated. After keg is done, list of accounts will show how much it costs for that account.
- after keg is done, creator of session will be able to export costs per joint account to settle up via API (https://api.settleup.io/)
- when someone else tap a beer for user, user will get notification
- theme will be in "beer" style
- all actions will be written into DB all other users will be pushed with new data



System Architecture (Tech Stack):

- Frontend: Cross-platform mobile framework (e.g., Flutter or React Native) for a unified codebase across iOS and Android.
- Backend & Database: Firebase/Firestore for real-time document syncing and offline persistence capabilities.
- Serverless Logic: Firebase Cloud Functions to securely interact with third-party APIs (Untappd API, Settle Up API) without exposing API keys on the client.
- Notifications: Firebase Cloud Messaging (FCM) to handle push notifications when someone taps a beer for another user.

Data Schema (High-Level):

- Users Collection: `user_id`, `nickname`, `weight`, `age`, `auth_provider`, `preferences`.
- KegSessions Collection: `session_id`, `creator_id`, `beer_name`, `volume_total`, `volume_remaining`, `price_per_volume`, `start_time`, `status` (active/paused/done).
- Pours Collection: `pour_id`, `session_id`, `user_id`, `poured_by_id` (if poured for someone else), `volume`, `timestamp`.
- JointAccounts Collection: `account_id`, `session_id`, `member_user_ids`, `group_name`.

Security, Privacy & Edge Cases:

- Concurrency & Race Conditions: Use Firestore transactions for pour operations to ensure the keg's remaining volume doesn't drop below zero if multiple users log a beer at the exact same millisecond.
- Mistake Handling (Undo): Implement an "Undo" action for accidental pours or incorrect volumes to maintain accurate billing and statistics without manual database intervention.
- Privacy & Compliance (GDPR): Store health-related data (weight, age, BAC) securely. Provide strict opt-in settings for sharing statistics. Ensure App Store compliance by adding "Drink Responsibly" warnings and disclaimers.
- Offline Architecture: Instead of building an immediate peer-to-peer offline hotspot feature (which adds massive architectural complexity), rely on Firebase's native offline persistence as a V1 solution. Users can pour drinks offline, and the app will queue those actions locally, syncing instantly when a standard internet connection is restored.


