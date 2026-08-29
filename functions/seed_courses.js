const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Safety invariant: this development seed script can only reach the local
// emulator. Never make the host or project point at a real Firebase project.
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8085";
admin.initializeApp({ projectId: "demo-intellia237" });
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
      console.log(`✅ Matière ${subjectId} insérée.`);

      // 3. Insérer les Chapitres (Chapters) et Leçons (Lessons)
      for (const chapter of courseData.chapters) {
        const chapterRef = subjectRef.collection('chapters').doc(chapter.chapterId);
        const publishedLessons = chapter.lessons.filter((lesson) => lesson.data.status === 'published');
        const lessonPreviews = publishedLessons.map((lesson) => ({
          id: lesson.lessonId,
          classLevel,
          subjectId,
          chapterId: chapter.chapterId,
          title: lesson.data.title || '',
          summary: lesson.data.summary || '',
          estimatedMinutes: Number(lesson.data.estimatedMinutes || 0),
          order: Number(lesson.data.order || 0),
        }));
        await chapterRef.set({
          ...chapter.data,
          classLevel,
          subjectId,
          lessonsCount: lessonPreviews.length,
          lessonPreviews,
        });
        console.log(`  ✅ Chapitre ${chapter.chapterId} inséré.`);

        for (const lesson of chapter.lessons) {
          const lessonRef = chapterRef.collection('lessons').doc(lesson.lessonId);
          await lessonRef.set({
            ...lesson.data,
            classLevel,
            subjectId,
            chapterId: chapter.chapterId,
          });
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
