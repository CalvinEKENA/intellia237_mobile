const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Safety invariant: this development seed script can only reach the local
// emulator. Never make the host or project point at a real Firebase project.
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";
if (!admin.apps.length) admin.initializeApp({ projectId: "demo-intellia237" });
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
        const chapterSummaries = courseData.chapters.map((chapter) => {
          const publishedLessons = chapter.lessons.filter((lesson) => lesson.data.status === 'published');
          return {
            id: chapter.chapterId,
            title: chapter.data.title || '',
            description: chapter.data.description || '',
            lessonsCount: publishedLessons.length,
            order: Number(chapter.data.order || 0),
          };
        });
        await subjectRef.set({ ...courseData.subject, chapterSummaries });

        for (const chapter of courseData.chapters) {
          const chapterRef = subjectRef.collection('chapters').doc(chapter.chapterId);
          const publishedLessons = chapter.lessons.filter((lesson) => lesson.data.status === 'published');
          const lessonPreviews = publishedLessons.map((lesson) => ({
            id: lesson.lessonId,
            classLevel: classLvl,
            subjectId,
            chapterId: chapter.chapterId,
            title: lesson.data.title || '',
            summary: lesson.data.summary || '',
            estimatedMinutes: Number(lesson.data.estimatedMinutes || 0),
            order: Number(lesson.data.order || 0),
          }));
          await chapterRef.set({
            ...chapter.data,
            classLevel: classLvl,
            subjectId,
            lessonsCount: lessonPreviews.length,
            lessonPreviews,
          });

          for (const lesson of chapter.lessons) {
            const lessonRef = chapterRef.collection('lessons').doc(lesson.lessonId);
            await lessonRef.set({
              ...lesson.data,
              classLevel: classLvl,
              subjectId,
              chapterId: chapter.chapterId,
            });
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
    const batch = db.batch();
    batch.set(quizRef, {
      title: "Test d'Anglais : Les bases",
      subjectId: "anglais",
      subjectLabel: "Anglais",
      description: "Un petit quiz généré automatiquement pour tester l'onglet Quiz.",
      difficultyLabel: "Facile",
      timerSeconds: 300,
      classLevels: ['Seconde', 'Première', 'Terminale'],
      status: 'published',
      mode: 'training',
      questions: [
        {
          id: "q1",
          type: "qcm",
          prompt: "Comment dit-on 'Naviguer sur internet' ?",
          options: ["To browse", "To print", "To download"],
          pointsReward: 10
        }
      ]
    });
    batch.set(db.collection('quiz_answer_keys').doc(quizRef.id), {
      answers: [{
        id: 'q1',
        correctOptionIndex: 0,
        explanation: "To browse signifie naviguer ou parcourir.",
        pointsReward: 10
      }]
    });
    await batch.commit();
    console.log(`\n[SEED] ✅ Quiz d'exemple inséré.`);
  } catch(e) {
    console.error("Erreur Quiz", e);
  }

  console.log("\n[SEED] 🎉 Terminé pour de bon !");
}

seedData();
