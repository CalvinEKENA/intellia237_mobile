"""Offline, deterministic pack/legacy JSON audit. No dependencies or network.

Usage: python -X utf8 tool/content/audit_content.py --output docs/content_engine/quiz_audit_after.json
ERROR is a reproducible contract failure. WARNING is a review signal, never a
claim that a scientific statement is wrong. IDs are scoped to their pack.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import unicodedata


def normalized(value):
    text = unicodedata.normalize('NFC', str(value)).lower()
    text = re.sub('[’‘ʼ`´]', "'", text)
    return re.sub(r'\s+', ' ', text).strip(' \t\r\n.,;:!?"\'«»“”')


def semantic_key(value):
    # Preserve numbers, signs, accents and words: changing these can reverse truth.
    return normalized(value).replace('−', '-')


def words(value):
    return set(re.findall(r"[\w]+(?:'[\w]+)?", normalized(value)))


def walk(value, path='$'):
    if isinstance(value, dict):
        yield path, value
        for key, child in value.items():
            yield from walk(child, f'{path}.{key}')
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, f'{path}[{index}]')


def audit_question(question, *, file, path, emit, lessons=None, concepts=None):
    qid = str(question.get('id', path))
    def issue(code, message, severity='WARNING', classification='PROBABLE'):
        emit(dict(severity=severity, classification=classification, code=code,
                  file=file, path=path, question_id=qid, message=message))

    kind = question.get('type', 'mcq' if 'options' in question else '')
    kind = {'qcm': 'mcq', 'trueFalse': 'true_false', 'shortAnswer': 'short_text'}.get(kind, kind)
    prompt = question.get('prompt', question.get('question', ''))
    answer = question.get('answer')
    choices = question.get('choices', question.get('options', []))
    labels = [c.get('label', c.get('text')) if isinstance(c, dict) else c for c in choices]
    if 'correctOptionIndex' in question or 'correctIndex' in question:
        index = question.get('correctOptionIndex', question.get('correctIndex'))
        answer = labels[index] if type(index) is int and 0 <= index < len(labels) else None
    if 'correctBooleanValue' in question:
        answer = question['correctBooleanValue']
    accepted = question.get('accepted_answers', question.get('acceptedAnswers', []))
    if kind == 'short_text' and answer is None and accepted:
        answer = accepted[0]
    manual = question.get('auto_score') is False
    if not isinstance(prompt, str) or not prompt.strip():
        issue('question_prompt_missing', 'Énoncé absent.', 'ERROR', 'CONFIRMED')
        prompt = ''
    if answer is None or answer == '' or answer == [] or answer == {}:
        if not (manual and question.get('model_answer')):
            issue('question_answer_missing', 'Réponse ou modèle absent.', 'ERROR', 'CONFIRMED')
    if 'difficulty' in question and question['difficulty'] not in [1, 2, 3]:
        issue('question_difficulty_invalid', 'Difficulté hors 1/2/3.', 'ERROR', 'CONFIRMED')
    if lessons is not None and question.get('lesson', 0) not in lessons | {0}:
        issue('question_lesson_unknown', 'Leçon absente du runtime.', 'ERROR', 'CONFIRMED')
    if concepts is not None and question.get('concept_id') and question['concept_id'] not in concepts:
        issue('question_concept_unknown', 'Concept absent de pedagogy.json.', 'ERROR', 'CONFIRMED')
    points = question.get('pointsReward', question.get('points'))
    if points is not None and (type(points) not in [int, float] or points < 0):
        issue('question_points_invalid', 'Points négatifs ou non numériques.', 'ERROR', 'CONFIRMED')
    if 'self_evaluation' in question.get('tags', []) and not manual:
        issue('self_evaluation_auto_scored', 'Autoévaluation déclarée comme objective.', 'ERROR', 'CONFIRMED')
    if kind in ['mcq', 'multi_select']:
        expected = answer if kind == 'multi_select' and isinstance(answer, list) else [answer]
        if len(labels) < 2:
            issue('question_choices_missing', 'Moins de deux choix.', 'ERROR', 'CONFIRMED')
        if any(value not in labels for value in expected):
            issue('correct_choice_not_found', 'Réponse absente des choix.', 'ERROR', 'CONFIRMED')
        if kind == 'mcq' and labels.count(answer) > 1:
            issue('multiple_correct_choices', 'Plusieurs choix portent la réponse exacte.', 'ERROR', 'CONFIRMED')
        normalized_labels = [normalized(label) for label in labels]
        if len(set(normalized_labels)) != len(normalized_labels):
            issue('ambiguous_normalized_answers', 'Choix identiques après normalisation typographique.', classification='CONFIRMED')
        metadata = question.get('option_metadata', [])
        by_id = {m.get('id'): m.get('label') for m in metadata}
        if 'correct_option_ids' in question:
            ids = question['correct_option_ids']
            mapped = [by_id.get(i) for i in ids]
            if sorted(map(str, mapped)) != sorted(map(str, expected)):
                issue('correct_option_ids_mismatch', 'Les identifiants corrects contredisent answer.', 'ERROR', 'CONFIRMED')
        feedback = {m.get('label'): m.get('feedback', '').strip() for m in metadata}
        missing = [label for label in labels if not feedback.get(label)]
        if missing:
            issue('choice_feedback_missing', f'{len(missing)} choix sans feedback spécifique.', classification='CONFIRMED')
        generic = [f for label, f in feedback.items() if label not in expected and f]
        if len(generic) > 1 and len(set(generic)) == 1:
            issue('choice_feedback_generic', 'Tous les distracteurs ont le même feedback : vérifier pourquoi chacun est faux.')
    if kind == 'true_false' and type(answer) is not bool:
        issue('true_false_answer_invalid', 'La réponse vrai/faux doit être un booléen JSON.', 'ERROR', 'CONFIRMED')
    if kind == 'short_text':
        answers = [answer] + [a for a in accepted if a != answer]
        if len({normalized(a) for a in answers}) < len(answers):
            issue('ambiguous_normalized_answers', 'Variantes textuelles redondantes après normalisation.', classification='CONFIRMED')
        if isinstance(answer, str) and re.search(r'[=√²³^<>≤≥]', answer):
            issue('question_math_is_text', 'Réponse mathématique déclarée short_text ; vérifier type et casse.')
        if isinstance(answer, str) and len(answer.split()) >= 2:
            issue('short_text_alternatives_review', 'Réponse textuelle exacte : vérifier les autres formulations légitimes.', classification='NEEDS_SOURCE_REVIEW')
    if kind == 'expression' and isinstance(answer, str):
        parts = answer.split()
        if parts and all(len(w) >= 2 and w.replace("'", '').replace('-', '').isalpha() for w in parts) and not any(w in ['sin', 'cos', 'tan', 'ln', 'log', 'sqrt', 'exp'] for w in parts):
            issue('question_expression_is_text', 'Réponse en mots déclarée expression mathématique.', 'ERROR', 'CONFIRMED')
    explanation = question.get('explanation', '')
    if not isinstance(explanation, str) or not explanation.strip():
        issue('explanation_missing', 'Pas d’explication après correction.', classification='CONFIRMED')
        explanation = ''
    if prompt and explanation:
        a, b = words(prompt), words(explanation)
        overlap = len(a & b) / max(1, len(a | b))
        if normalized(prompt) == normalized(explanation) or (len(a) >= 5 and overlap >= .85):
            issue('explanation_near_duplicate_of_prompt', 'Explication identique ou très proche de l’énoncé.')
    for index, hint in enumerate(question.get('hints', [])):
        text = hint.get('content', '') if isinstance(hint, dict) else hint
        if not isinstance(text, str) or not text.strip():
            issue('hint_empty', f'Indice {index + 1} vide.', classification='CONFIRMED')
        elif normalized(text) in ['réfléchis', 'think', 'relis la question', 'read the question']:
            issue('hint_unhelpful', f'Indice {index + 1} sans stratégie.')
        elif isinstance(answer, (str, int, float)) and not isinstance(answer, bool):
            target = normalized(answer)
            hint_text = normalized(text)
            if isinstance(answer, (int, float)):
                hint_text = re.sub(r'(?<=\d),(?=\d)', '.', hint_text)
            if target and re.search(r'(?<![\w.])' + re.escape(target) + r'(?![\w.])', hint_text):
                # Answer occurrence is factual, answer leakage remains contextual.
                issue('hint_reveals_answer', f'Indice {index + 1} contient la réponse exacte {answer!r}.')
    return {'id': qid, 'type': kind, 'prompt': prompt, 'answer': answer,
            'manual': manual, 'choices': labels}


def audit(root: Path):
    findings, inventory, packs, legacy = [], [], [], []
    content = root / 'assets/content'
    documents = {}
    for file in sorted(content.rglob('*.json')):
        rel = file.relative_to(root).as_posix()
        raw = file.read_bytes()
        inventory.append({'file': rel, 'sha256': hashlib.sha256(raw).hexdigest()})
        try:
            documents[file] = json.loads(raw.decode('utf-8-sig'))
        except (ValueError, UnicodeError) as error:
            findings.append(dict(severity='ERROR', classification='CONFIRMED', code='json_invalid', file=rel, path='$', question_id=None, message=str(error)))
    for file, runtime in documents.items():
        if file.name != 'runtime.json':
            continue
        rel = file.relative_to(root).as_posix()
        directory = file.parent
        manifest = documents.get(directory / 'manifest.json', {})
        pedagogy = documents.get(directory / 'pedagogy.json', {})
        source = documents.get(directory / 'source.json', {})
        for required in ['manifest.json', 'source.json', 'pedagogy.json', 'validation_report.json']:
            if directory / required not in documents:
                findings.append(dict(severity='ERROR', classification='CONFIRMED', code='pack_file_missing', file=rel, path='$', question_id=None, message=f'{required} absent.'))
        raw_concepts = pedagogy.get('concepts', [])
        concepts = set(raw_concepts) if isinstance(raw_concepts, dict) else {c['id'] for c in raw_concepts}
        lessons = {l['lesson'] for l in runtime.get('lessons', runtime.get('lesson_refs', []))}
        questions, ids, prompts = [], set(), {}
        for index, q in enumerate(runtime.get('question_bank', [])):
            path = f'$.question_bank[{index}]'
            record = audit_question(q, file=rel, path=path, emit=findings.append, lessons=lessons, concepts=concepts)
            if record['id'] in ids:
                findings.append(dict(severity='ERROR', classification='CONFIRMED', code='duplicate_question_id', file=rel, path=path, question_id=record['id'], message='Identifiant déjà utilisé dans ce pack.'))
            ids.add(record['id'])
            key = semantic_key(record['prompt'])
            if key in prompts:
                findings.append(dict(severity='WARNING', classification='PROBABLE', code='duplicate_question_semantics', file=rel, path=path, question_id=record['id'], message=f'Énoncé identique à {prompts[key]}.'))
            prompts[key] = record['id']
            questions.append(record)
        # Same words with high overlap = candidate only, not proof of duplicate.
        for i, a in enumerate(questions):
            aw = words(a['prompt'])
            for b in questions[:i]:
                bw = words(b['prompt'])
                if a['type'] == b['type'] and a['prompt'] != b['prompt'] and len(aw) >= 8 and len(aw & bw) / max(1, len(aw | bw)) >= .88:
                    findings.append(dict(severity='WARNING', classification='PROBABLE', code='near_duplicate_question_semantics', file=rel, path=f'$.question_bank[{i}]', question_id=a['id'], message=f'Énoncé très proche de {b["id"]} ; comparer données et objectif.'))
        positions = Counter(q['choices'].index(q['answer']) for q in questions if q['type'] == 'mcq' and q['answer'] in q['choices'])
        if sum(positions.values()) >= 5 and max(positions.values()) / sum(positions.values()) >= .8:
            findings.append(dict(severity='WARNING', classification='CONFIRMED', code='correct_choice_position_bias', file=rel, path='$.question_bank', question_id=None, message=f'Positions correctes dans les données : {dict(sorted(positions.items()))}. UI mélange par tentative ; maintenir les tests.'))
        flags = []
        quality = source.get('source_quality', {})
        if quality:
            flags.append(quality)
        packs.append(dict(id=manifest.get('id', runtime.get('pack_id')), directory=directory.relative_to(root).as_posix(), questions=len(questions), explicitly_manual=sum(q['manual'] for q in questions), types=dict(sorted(Counter(q['type'] for q in questions).items())), correct_choice_positions=dict(sorted(positions.items())), source_quality=flags))
    # Legacy embedded quiz JSON: all assets outside Content Engine, not fixtures.
    legacy_files = 0
    for file in sorted((root / 'assets').rglob('*.json')):
        if file.is_relative_to(content):
            continue
        legacy_files += 1
        try:
            document = json.loads(file.read_text(encoding='utf-8-sig'))
        except (ValueError, UnicodeError):
            continue
        for path, obj in walk(document):
            if ('prompt' in obj or 'question' in obj) and any(k in obj for k in ['correctOptionIndex', 'correctIndex', 'correctBooleanValue', 'acceptedAnswers']):
                legacy.append(audit_question(obj, file=file.relative_to(root).as_posix(), path=path, emit=findings.append))
    findings.sort(key=lambda d: (d['file'], d['path'], d['code']))
    return dict(schema_version=1, scope='Offline repository snapshot; no cloud production query',
                counts=dict(packs=len(packs), questions=sum(p['questions'] for p in packs), explicitly_manual=sum(p['explicitly_manual'] for p in packs), content_json_files=len(inventory), legacy_json_files_scanned=legacy_files, legacy_embedded_questions=len(legacy), errors=sum(f['severity'] == 'ERROR' for f in findings), warnings=sum(f['severity'] == 'WARNING' for f in findings)),
                diagnostics_by_code=dict(sorted(Counter(f['code'] for f in findings).items())),
                classifications=dict(sorted(Counter(f['classification'] for f in findings).items())),
                packs=packs, inventory=inventory, findings=findings,
                limitations=['No cloud quiz corpus export in the repository: remote question count unknown.', 'Lexical heuristics cannot prove scientific truth, grammatical correctness, distractor quality, difficulty or source faithfulness.', 'Source exercise counts are not inferred from heterogeneous extraction schemas; runtime question count is exact.', 'explicitly_manual counts auto_score:false; parser also infers written self-evaluation from non-scorable prose.'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = audit(args.root.resolve())
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result['counts'], ensure_ascii=False, sort_keys=True))
    for finding in result['findings']:
        print(f"{finding['severity']} {finding['code']} {finding['file']}:{finding['path']} [{finding['classification']}] {finding['message']}")
    return int(result['counts']['errors'] > 0)


if __name__ == '__main__':
    raise SystemExit(main())
