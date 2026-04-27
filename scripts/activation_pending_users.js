const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'ondyn-beerer' });

const auth = admin.auth();

async function main() {
  let pageToken;
  let count = 0;

  do {
    const result = await auth.listUsers(1000, pageToken);
    for (const user of result.users) {
      if (!user.emailVerified) {
        console.log(user.uid, user.email, user.metadata.creationTime);
        count++;
      }
    }
    pageToken = result.pageToken;
  } while (pageToken);

  console.log(`\nTotal unverified: ${count}`);
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});