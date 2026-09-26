import type { ReserveAggregate } from "../../services/studyReserve";
import type {
  StudentEntitlement,
  StudyReservePlanConfig,
  StudyReserveProvisioningStore,
} from "../../services/studyReserveProvisioning";

/** Fin de fenêtre lointaine mais représentable en date ISO. */
const OPEN_WINDOW_END_MS = Date.UTC(2100, 0, 1);

/**
 * Double de provisionnement pour les tests qui scellent directement un agrégat :
 * l'agrégat existant d'un élève est présenté comme le cycle EN COURS d'un
 * entitlement actif (offre = élève, fenêtre ouverte, sans cadence), si bien que
 * `ensureCurrentStudyReserveCycle` le renvoie tel quel, sans reset.
 * Aucun agrégat → aucun entitlement → réserve « unavailable ».
 *
 * Le chemin réel entitlement → offre → plan est couvert par
 * studyReserveProvisioning.test.ts et par le test d'intégration émulateur.
 */
export class CurrentCycleProvisioning implements StudyReserveProvisioningStore {
  constructor(
    private readonly reads: (studentId: string) => Promise<ReserveAggregate | null>,
  ) {}

  async resolveEntitlement(studentId: string): Promise<StudentEntitlement | null> {
    const aggregate = await this.reads(studentId);
    if (!aggregate || aggregate.allowanceInternal <= 0) return null;
    return {
      offerId: studentId,
      windowStartMs: 0,
      windowEndMs: OPEN_WINDOW_END_MS,
      active: true,
    };
  }

  async planConfig(offerId: string): Promise<StudyReservePlanConfig | null> {
    const aggregate = await this.reads(offerId);
    return aggregate ? { allowanceInternal: aggregate.allowanceInternal, cycleDays: null } : null;
  }

  async readAggregate(studentId: string): Promise<ReserveAggregate | null> {
    const aggregate = await this.reads(studentId);
    return aggregate ? { ...aggregate, cycleId: `${studentId}_0` } : null;
  }

  async provisionCycle(_studentId: string, fresh: ReserveAggregate): Promise<ReserveAggregate> {
    return fresh;
  }

  async updateCurrentCycle(): Promise<ReserveAggregate | null> {
    return null;
  }
}
