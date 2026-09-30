import copy
import json
from pathlib import Path
import tempfile
import unittest

from audit_content import audit, audit_question


class ContentAuditTest(unittest.TestCase):
    def setUp(self):
        self.question = dict(id='q', type='mcq', prompt='Quel résultat ?', answer='A',
                             choices=['A', 'B'], explanation='La relation conduit à A.',
                             difficulty=1, lesson=1, concept_id='c')

    def codes(self, **changes):
        q = {**copy.deepcopy(self.question), **changes}
        findings = []
        audit_question(q, file='runtime.json', path='$.question_bank[0]',
                       emit=findings.append, lessons={1}, concepts={'c'})
        return {f['code'] for f in findings}

    def test_missing_answer(self):
        self.assertIn('question_answer_missing', self.codes(answer=None))

    def test_answer_not_in_choices(self):
        self.assertIn('correct_choice_not_found', self.codes(answer='C'))

    def test_multiple_identical_correct_choices(self):
        self.assertIn('multiple_correct_choices', self.codes(choices=['A', 'A']))

    def test_false_is_a_valid_answer(self):
        self.assertNotIn('question_answer_missing', self.codes(type='true_false', answer=False))
        self.assertIn('true_false_answer_invalid', self.codes(type='true_false', answer='false'))

    def test_semantic_warnings_are_not_errors(self):
        self.assertIn('explanation_near_duplicate_of_prompt', self.codes(explanation='Quel résultat ?'))
        self.assertIn('hint_reveals_answer', self.codes(type='numeric', answer=.68, hints=['Autour de 0,68.']))

    def test_normalized_apostrophes(self):
        self.assertIn('ambiguous_normalized_answers', self.codes(choices=["l'eau", 'l’eau'], answer="l'eau"))

    def test_wrong_scoring_mode(self):
        self.assertIn('self_evaluation_auto_scored', self.codes(tags=['self_evaluation']))
        self.assertNotIn('self_evaluation_auto_scored', self.codes(tags=['self_evaluation'], auto_score=False))

    def test_expression_text_and_math_text(self):
        self.assertIn('question_expression_is_text', self.codes(type='expression', answer='calm down'))
        self.assertIn('question_math_is_text', self.codes(type='short_text', answer='T=2t'))

    def test_incorrect_metadata(self):
        self.assertIn('correct_option_ids_mismatch', self.codes(option_metadata=[dict(id='a', label='B')], correct_option_ids=['a']))

    def test_recursive_scan_lesson_refs_duplicate_ids_and_determinism(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            directory = root / 'assets/content/a/b/c'
            directory.mkdir(parents=True)
            documents = {
                'manifest.json': {'id': 'test'}, 'source.json': {}, 'validation_report.json': {},
                'pedagogy.json': {'concepts': [{'id': 'c'}]},
                'runtime.json': {'lesson_refs': [{'lesson': 1}], 'question_bank': [self.question, self.question]},
            }
            for name, document in documents.items():
                (directory / name).write_text(json.dumps(document), encoding='utf-8')
            result = audit(root)
            self.assertEqual(result, audit(root))
            self.assertEqual(result['counts']['packs'], 1)
            self.assertEqual(result['counts']['questions'], 2)
            self.assertIn('duplicate_question_id', result['diagnostics_by_code'])
            self.assertNotIn('question_lesson_unknown', result['diagnostics_by_code'])

    def test_legacy_embedded_json(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'assets').mkdir()
            (root / 'assets/legacy.json').write_text(json.dumps({'questions': [dict(id='old', type='qcm', prompt='Combien ?', options=['2', '3'], correctOptionIndex=1, explanation='Trois objets.')] }), encoding='utf-8')
            result = audit(root)
            self.assertEqual(result['counts']['legacy_embedded_questions'], 1)
            self.assertEqual(result['counts']['errors'], 0)


if __name__ == '__main__':
    unittest.main()
