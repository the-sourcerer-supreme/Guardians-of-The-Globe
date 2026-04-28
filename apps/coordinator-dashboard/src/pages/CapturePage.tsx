import { useEffect, useMemo, useState } from "react";
import { useAppState } from "../state/AppStateContext";
import type { DraftNeedInput } from "../types";

const draftKey = "guardians-capture-draft";

const emptyDraft: DraftNeedInput = {
  title: "",
  description: "",
  needType: "Water",
  urgency: 3,
  peopleAffected: 1,
  locationName: "",
  lat: "",
  lng: ""
};

interface CapturePageProps {
  onSaved(): void;
}

export function CapturePage({ onSaved }: CapturePageProps) {
  const { createNeed } = useAppState();
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState<DraftNeedInput>(() => {
    const raw = window.localStorage.getItem(draftKey);
    return raw ? (JSON.parse(raw) as DraftNeedInput) : emptyDraft;
  });

  useEffect(() => {
    window.localStorage.setItem(draftKey, JSON.stringify(form));
  }, [form]);

  const canSubmit = useMemo(() => {
    return (
      form.title.trim().length > 4 &&
      form.description.trim().length > 10 &&
      form.locationName.trim().length > 2 &&
      form.lat.trim() !== "" &&
      form.lng.trim() !== ""
    );
  }, [form]);

  return (
    <div className="page-stack">
      <section className="panel wide-panel">
        <div className="panel-header">
          <div>
            <h3>Field Intake</h3>
            <p className="panel-subtitle">Three-minute need capture with draft autosave.</p>
          </div>
          <button
            className="secondary-button"
            onClick={() => setForm(emptyDraft)}
            type="button"
          >
            Reset draft
          </button>
        </div>

        <div className="form-grid">
          <label className="field">
            <span>Need title</span>
            <input
              value={form.title}
              onChange={(event) => setForm({ ...form, title: event.target.value })}
              placeholder="Emergency food packets for 20 people"
            />
          </label>

          <label className="field">
            <span>Need type</span>
            <select
              value={form.needType}
              onChange={(event) => setForm({ ...form, needType: event.target.value })}
            >
              <option>Water</option>
              <option>Food</option>
              <option>Shelter</option>
              <option>Transport</option>
              <option>Medical</option>
              <option>Documentation</option>
            </select>
          </label>

          <label className="field">
            <span>Description</span>
            <textarea
              value={form.description}
              onChange={(event) => setForm({ ...form, description: event.target.value })}
              rows={5}
              placeholder="What is needed, for whom, and what is the immediate risk?"
            />
          </label>

          <div className="inline-grid">
            <label className="field">
              <span>Urgency</span>
              <input
                type="range"
                min="1"
                max="5"
                value={form.urgency}
                onChange={(event) =>
                  setForm({ ...form, urgency: Number(event.target.value) })
                }
              />
              <small>{form.urgency} / 5</small>
            </label>

            <label className="field">
              <span>People affected</span>
              <input
                type="number"
                min="1"
                value={form.peopleAffected}
                onChange={(event) =>
                  setForm({ ...form, peopleAffected: Number(event.target.value) })
                }
              />
            </label>
          </div>

          <label className="field">
            <span>Location name</span>
            <input
              value={form.locationName}
              onChange={(event) => setForm({ ...form, locationName: event.target.value })}
              placeholder="Ward 7, Govandi"
            />
          </label>

          <div className="inline-grid">
            <label className="field">
              <span>Latitude</span>
              <input
                value={form.lat}
                onChange={(event) => setForm({ ...form, lat: event.target.value })}
                placeholder="19.0760"
              />
            </label>

            <label className="field">
              <span>Longitude</span>
              <input
                value={form.lng}
                onChange={(event) => setForm({ ...form, lng: event.target.value })}
                placeholder="72.8777"
              />
            </label>
          </div>
        </div>

        <div className="form-actions">
          <button
            className="primary-button"
            disabled={!canSubmit || busy}
            onClick={async () => {
              setBusy(true);
              try {
                await createNeed(form);
                window.localStorage.removeItem(draftKey);
                setForm(emptyDraft);
                onSaved();
              } finally {
                setBusy(false);
              }
            }}
            type="button"
          >
            {busy ? "Saving..." : "Save need"}
          </button>
          <p className="panel-meta">Draft stays on this device until submitted to Firestore.</p>
        </div>
      </section>
    </div>
  );
}
