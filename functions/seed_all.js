const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";

// Remplacez 'edunova-aabd1' par le nom de votre projet
if (!admin.apps.length) admin.initializeApp({ projectId: "edunova-aabd1" });
const db = admin.firestore();

async function seedData() {
  const filesToSeed = ['cours_anglais_terminale.json', 'cours_svt_terminale.json'];
  // On pousse dans plusieurs classes pour être sûr que vous le voyez
  // peu importe la classe enregistrée sur votre profil actuel.
  const classesTarget = ['Seconde', 'Première', 'Terminale'];

  for (const fileName of filesToSeed) {
    try {
      const filePath = path.join(__dirname, fileName);
      const rawData = fs.readFileSync(filePath, 'utf-8');
      const courseData = JSON.parse(rawData);

      const subjectId = courseData.subjectId;

      for (const classLvl of classesTarget) {
        console.log(`\n[SEED] Insertion de ${courseData.subject.title} pour la classe de ${classLvl}...`);
        const subjectRef = db.collection('classes').doc(classLvl).collection('subjects').doc(subjectId);
        await subjectRef.set(courseData.subject);

        for (const chapter of courseData.chapters) {
          const chapterRef = subjectRef.collection('chapters').doc(chapter.chapterId);
          await chapterRef.set(chapter.data);

          for (const lesson of chapter.lessons) {
            const lessonRef = chapterRef.collection('lessons').doc(lesson.lessonId);
            await lessonRef.set(lesson.data);
          }
        }
      }
    } catch (error) {
      console.error(`❌ Erreur sur ${fileName}:`, error);
    }
  }

  // Insertion d'un QUIZ de base pour tester l'onglet Quiz
  try {
    const quizRef = db.collection('quizzes').doc('english_quiz_1');
    await quizRef.set({
      title: "Test d'Anglais : Les bases",
      subjectId: "anglais",
      subjectLabel: "Anglais",
      description: "Un petit quiz généré automatiquement pour tester l'onglet Quiz.",
      difficultyLabel: "Facile",
      timerSeconds: 300,
      classLevels: ['Seconde', 'Première', 'Terminale'],
      status: 'published',
      questions: [
        {
          id: "q1",
          type: "qcm",
          prompt: "Comment dit-on 'Naviguer sur internet' ?",
          options: ["To browse", "To print", "To download"],
          correctOptionIndex: 0,
          explanation: "To browse signifie naviguer ou parcourir."
        }
      ]
    });
    console.log(`\n[SEED] ✅ Quiz d'exemple inséré.`);
  } catch(e) {
    console.error("Erreur Quiz", e);
  }

  console.log("\n[SEED] 🎉 Terminé pour de bon !");
}

seedData();
