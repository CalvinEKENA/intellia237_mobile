const admin = require('firebase-admin');

// Safety invariant: this helper only inspects the local Firestore emulator.
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";
if (!admin.apps.length) admin.initializeApp({ projectId: "demo-intellia237" });
const db = admin.firestore();

async function check() {
  const snap = await db.collection('classes').doc('Terminale').collection('subjects').get();
  console.log(`Found ${snap.docs.length} subjects in Terminale.`);
  snap.docs.forEach(d => {
    console.log(d.id, d.data().status, d.data().title);
  });
}

check();
