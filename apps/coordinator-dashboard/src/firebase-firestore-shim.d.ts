declare module "firebase/firestore" {
  export interface Firestore {}

  export interface CollectionReference<T = Record<string, unknown>> {}

  export interface DocumentReference<T = Record<string, unknown>> {}

  export interface DocumentSnapshot<T = Record<string, unknown>> {
    readonly id: string;
    exists(): boolean;
    data(): T | undefined;
  }

  export interface QueryDocumentSnapshot<T = Record<string, unknown>> {
    readonly id: string;
    data(): T;
  }

  export interface QuerySnapshot<T = Record<string, unknown>> {
    readonly docs: QueryDocumentSnapshot<T>[];
  }

  export interface WriteBatch {
    set(
      reference: DocumentReference,
      data: Record<string, unknown>,
      options?: { merge?: boolean }
    ): void;
    update(reference: DocumentReference, data: Record<string, unknown>): void;
    commit(): Promise<void>;
  }

  export function getFirestore(app?: unknown): Firestore;
  export function collection(
    target: Firestore | CollectionReference,
    path: string
  ): CollectionReference;
  export function doc(
    target: Firestore | CollectionReference,
    path?: string,
    ...pathSegments: string[]
  ): DocumentReference;
  export function where(fieldPath: string, opStr: string, value: unknown): unknown;
  export function query(
    target: CollectionReference,
    ...queryConstraints: unknown[]
  ): unknown;
  export function onSnapshot<T = Record<string, unknown>>(
    target: unknown,
    observer: (snapshot: QuerySnapshot<T>) => void
  ): () => void;
  export function getDoc<T = Record<string, unknown>>(
    reference: DocumentReference<T>
  ): Promise<DocumentSnapshot<T>>;
  export function setDoc(
    reference: DocumentReference,
    data: Record<string, unknown>,
    options?: { merge?: boolean }
  ): Promise<void>;
  export function writeBatch(db: Firestore): WriteBatch;
}
