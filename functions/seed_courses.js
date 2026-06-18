const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Initialiser Firebase.
// Ciblage de la PRODUCTION : la ligne émulateur est commentée.
// process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";

// Remplacez 'edunova-aabd1' par le nom de votre projet si nécessaire.
admin.initializeApp({ projectId: "edunova-aabd1" });
const db = admin.firestore();

async function seedData() {
  const filesToSeed = ['cours_anglais_terminale.json', 'cours_svt_terminale.json'];

  for (const fileName of filesToSeed) {
    try {
      const filePath = path.join(__dirname, fileName);
      const rawData = fs.readFileSync(filePath, 'utf-8');
      const courseData = JSON.parse(rawData);

      const classLevel = courseData.classLevel;
      const subjectId = courseData.subjectId;

      console.log(`\n[SEED] Insertion du cours : ${courseData.subject.title} pour la classe de ${classLevel} à partir de ${fileName}...`);

      // 2. Insérer la Matière (Subject)
      const subjectRef = db.collection('classes').doc(classLevel).collection('subjects').doc(subjectId);
      await subjectRef.set(courseData.subject);
      console.log(`✅ Matière ${subjectId} insérée.`);

      // 3. Insérer les Chapitres (Chapters) et Leçons (Lessons)
      for (const chapter of courseData.chapters) {
        const chapterRef = subjectRef.collection('chapters').doc(chapter.chapterId);
        await chapterRef.set(chapter.data);
        console.log(`  ✅ Chapitre ${chapter.chapterId} inséré.`);

        for (const lesson of chapter.lessons) {
          const lessonRef = chapterRef.collection('lessons').doc(lesson.lessonId);
          await lessonRef.set(lesson.data);
          console.log(`    ✅ Leçon ${lesson.lessonId} insérée.`);
        }
      }
    } catch (error) {
      console.error(`[SEED] ❌ Erreur lors de l'importation de ${fileName} :`, error);
    }
  }

  console.log("\n[SEED] 🎉 Importation de tous les fichiers terminée avec succès !");
}

seedData();
