const axios = require('axios');
const admin = require('firebase-admin');

// Configuration Admin pour l'émulateur
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";
admin.initializeApp({ projectId: "edunova-aabd1" });
const db = admin.firestore();

async function testGLM() {
    const FUNCTIONS_URL = 'http://127.0.0.1:5005/edunova-aabd1/europe-west1/generateQuiz';
    const AUTH_URL = 'http://127.0.0.1:9100/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key';
    const COURSE_ID = "test-course-" + Date.now();

    console.log("1. Préparation d'un cours PUBLIÉ dans Firestore...");
    await db.collection('courses').doc(COURSE_ID).set({
        title: "Les Volcans",
        subject: "Géographie",
        gradeLevel: "6ème",
        language: "fr",
        status: "published", // Crucial pour passer la validation !
        contentSections: [
            {
                title: "Introduction",
                body: "Un volcan est une ouverture de la croûte terrestre par laquelle s'échappe du magma, sous forme de lave. Les volcans se trouvent souvent à la limite des plaques tectoniques."
            }
        ],
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("2. Création d'un utilisateur de test...");
    let idToken;
    try {
        const authResp = await axios.post(AUTH_URL, {
            email: "test-" + Date.now() + "@intellia237.ai",
            password: "password123",
            returnSecureToken: true
        });
        idToken = authResp.data.idToken;
    } catch (e) {
        console.error("Erreur Auth:", e.response ? e.response.data : e.message);
        return;
    }

    console.log("3. Appel de generateQuiz (GLM-5.1)...");
    try {
        const resp = await axios.post(FUNCTIONS_URL, {
            data: {
                courseId: COURSE_ID,
                count: 1,
                difficulty: "easy"
            }
        }, {
            headers: { 'Authorization': `Bearer ${idToken}` }
        });

        console.log("4. Succès TOTAL ! Réponse de l'IA GLM-5.1 :");
        console.log(JSON.stringify(resp.data.result, null, 2));
    } catch (e) {
        console.error("Erreur Function:", e.response ? e.response.data : e.message);
    }
}

testGLM();
