const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp({ projectId: "edunova-aabd1" });
const db = admin.firestore();

async function check() {
  const snap = await db.collection('classes').doc('Terminale').collection('subjects').get();
  console.log(`Found ${snap.docs.length} subjects in Terminale.`);
  snap.docs.forEach(d => {
    console.log(d.id, d.data().status, d.data().title);
  });
}

check();
