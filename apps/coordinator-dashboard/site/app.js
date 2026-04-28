(function () {
  const APP_KEY = "guardians-static-mvp";
  const DRAFT_KEY = "guardians-static-draft";

  const seedState = {
    session: null,
    view: "dashboard",
    selectedNeedId: "need-001",
    needs: [
      {
        id: "need-001",
        organizationId: "guardians",
        title: "Water cans needed for 18 families",
        description: "Local supply stopped after line damage. Urgent drinking water support needed.",
        needType: "Water",
        urgency: 5,
        peopleAffected: 18,
        locationName: "Dharavi Sector 4",
        lat: 19.0419,
        lng: 72.8554,
        status: "open",
        createdAt: isoMinutesAgo(25),
        updatedAt: isoMinutesAgo(25),
        createdBy: "Farah Khan"
      },
      {
        id: "need-002",
        organizationId: "guardians",
        title: "Wheelchair transport to clinic",
        description: "Elderly resident needs transport support for scheduled treatment.",
        needType: "Transport",
        urgency: 4,
        peopleAffected: 1,
        locationName: "Sion East",
        lat: 19.0469,
        lng: 72.8631,
        status: "assigned",
        createdAt: isoMinutesAgo(90),
        updatedAt: isoMinutesAgo(35),
        createdBy: "Arjun Rao",
        assignedVolunteerId: "vol-002"
      },
      {
        id: "need-003",
        organizationId: "guardians",
        title: "Dry ration packets for temporary shelter",
        description: "Shelter coordinator requested dry food stocks for the next 24 hours.",
        needType: "Food",
        urgency: 3,
        peopleAffected: 42,
        locationName: "Kurla West",
        lat: 19.0728,
        lng: 72.8826,
        status: "triaged",
        createdAt: isoMinutesAgo(180),
        updatedAt: isoMinutesAgo(100),
        createdBy: "Nisha Salvi"
      }
    ],
    volunteers: [
      {
        id: "vol-001",
        name: "Sana Shaikh",
        phone: "+91 90000 11111",
        skills: ["Food", "Water", "Assessment"],
        status: "available",
        lat: 19.0583,
        lng: 72.8606,
        lastActiveAt: isoMinutesAgo(7)
      },
      {
        id: "vol-002",
        name: "Rohan Deshmukh",
        phone: "+91 90000 22222",
        skills: ["Transport", "Medical Escort"],
        status: "busy",
        lat: 19.0497,
        lng: 72.8681,
        lastActiveAt: isoMinutesAgo(2)
      },
      {
        id: "vol-003",
        name: "Meera Joshi",
        phone: "+91 90000 33333",
        skills: ["Shelter", "Food", "Documentation"],
        status: "available",
        lat: 19.076,
        lng: 72.8777,
        lastActiveAt: isoMinutesAgo(16)
      }
    ],
    tasks: [
      {
        id: "task-001",
        needId: "need-002",
        volunteerId: "vol-002",
        needTitle: "Wheelchair transport to clinic",
        volunteerName: "Rohan Deshmukh",
        status: "accepted",
        createdAt: isoMinutesAgo(35)
      }
    ]
  };

  let state = loadState();
  const root = document.getElementById("app");

  render();

  root.addEventListener("click", onClick);
  root.addEventListener("input", onInput);
  root.addEventListener("submit", onSubmit);

  function isoMinutesAgo(minutes) {
    return new Date(Date.now() - minutes * 60 * 1000).toISOString();
  }

  function loadState() {
    try {
      const raw = window.localStorage.getItem(APP_KEY);
      return raw ? JSON.parse(raw) : structuredClone(seedState);
    } catch {
      return structuredClone(seedState);
    }
  }

  function saveState() {
    window.localStorage.setItem(APP_KEY, JSON.stringify(state));
  }

  function saveDraft(formData) {
    window.localStorage.setItem(DRAFT_KEY, JSON.stringify(formData));
  }

  function loadDraft() {
    try {
      const raw = window.localStorage.getItem(DRAFT_KEY);
      return raw
        ? JSON.parse(raw)
        : {
            title: "",
            description: "",
            needType: "Water",
            urgency: "3",
            peopleAffected: "1",
            locationName: "",
            lat: "",
            lng: ""
          };
    } catch {
      return {
        title: "",
        description: "",
        needType: "Water",
        urgency: "3",
        peopleAffected: "1",
        locationName: "",
        lat: "",
        lng: ""
      };
    }
  }

  function render() {
    root.innerHTML = state.session ? renderWorkspace() : renderLogin();
  }

  function renderLogin() {
    return `
      <div class="login-shell">
        <form class="login-card" data-form="login">
          <div class="brand-mark">GG</div>
          <h1>Guardians of the Globe</h1>
          <p class="muted-text">Free-tier starter build. This runs entirely in the browser with no paid services.</p>

          <label class="field">
            <span>Name</span>
            <input name="displayName" value="Asha Patel" required />
          </label>

          <label class="field">
            <span>Email</span>
            <input name="email" value="asha@guardians.local" required />
          </label>

          <label class="field">
            <span>Workspace</span>
            <select name="role">
              <option value="coordinator">Coordinator</option>
              <option value="field_agent">Field Agent</option>
            </select>
          </label>

          <button class="primary-button full-width" type="submit">Enter workspace</button>
        </form>
      </div>
    `;
  }

  function renderWorkspace() {
    const draft = loadDraft();
    const selectedNeed = state.needs.find((need) => need.id === state.selectedNeedId) || state.needs[0] || null;
    const metrics = {
      openNeeds: state.needs.filter((need) => need.status !== "resolved").length,
      criticalQueue: state.needs.filter((need) => need.status !== "resolved" && need.urgency >= 4).length,
      availableVolunteers: state.volunteers.filter((volunteer) => volunteer.status === "available").length,
      activeTasks: state.tasks.filter((task) => task.status !== "completed").length
    };

    return `
      <div class="app-shell">
        <aside class="sidebar">
          <div>
            <div class="brand-mark">GG</div>
            <h1>Guardians of the Globe</h1>
            <p class="muted-text">Free-tier field response workspace</p>
          </div>

          <nav class="nav-list">
            ${navButton("dashboard", "Dashboard")}
            ${navButton("capture", "Field Intake")}
            ${navButton("tasks", "Tasks")}
            ${navButton("volunteers", "Volunteers")}
            ${navButton("map", "Map")}
          </nav>

          <div class="mode-card">
            <span class="status-dot ok"></span>
            <div>
              <strong>Local mode</strong>
              <p class="muted-text">No paid backend required for this starter.</p>
            </div>
          </div>
        </aside>

        <main class="main-content">
          <header class="topbar">
            <div>
              <p class="eyebrow">Operations</p>
              <h2>${state.session.role === "field_agent" ? "Field Agent Workspace" : "Coordinator Console"}</h2>
            </div>
            <div class="topbar-actions">
              <div class="user-chip">
                <strong>${escapeHtml(state.session.displayName)}</strong>
                <span>${escapeHtml(state.session.email)}</span>
              </div>
              <button class="secondary-button" data-action="logout" type="button">Sign out</button>
            </div>
          </header>

          <section class="page-stack ${state.view === "dashboard" ? "" : "hidden"}">
            <div class="metrics-grid">
              ${metricCard("Open needs", metrics.openNeeds, "neutral")}
              ${metricCard("Critical queue", metrics.criticalQueue, "critical")}
              ${metricCard("Available volunteers", metrics.availableVolunteers, "good")}
              ${metricCard("Active tasks", metrics.activeTasks, "neutral")}
            </div>

            <div class="content-grid">
              <div class="panel">
                <div class="panel-header">
                  <h3>Open Needs</h3>
                  <span class="panel-meta">${state.needs.length} total</span>
                </div>
                <div class="stack-list">
                  ${state.needs.map(renderNeedCard).join("")}
                </div>
              </div>

              <div class="panel">
                ${selectedNeed ? renderNeedDetail(selectedNeed) : "<h3>No need selected</h3>"}
              </div>
            </div>
          </section>

          <section class="page-stack ${state.view === "capture" ? "" : "hidden"}">
            <div class="panel">
              <div class="panel-header">
                <div>
                  <h3>Field Intake</h3>
                  <p class="panel-subtitle">Three-minute need capture with autosaved local draft.</p>
                </div>
                <button class="secondary-button" type="button" data-action="reset-draft">Reset draft</button>
              </div>

              <form class="capture-form" data-form="capture">
                <div class="form-grid">
                  <label class="field">
                    <span>Need title</span>
                    <input name="title" value="${escapeAttribute(draft.title)}" required />
                  </label>

                  <label class="field">
                    <span>Need type</span>
                    <select name="needType">
                      ${["Water", "Food", "Shelter", "Transport", "Medical", "Documentation"]
                        .map((item) => `<option ${draft.needType === item ? "selected" : ""}>${item}</option>`)
                        .join("")}
                    </select>
                  </label>

                  <label class="field">
                    <span>Description</span>
                    <textarea name="description" rows="5" required>${escapeHtml(draft.description)}</textarea>
                  </label>

                  <div class="inline-grid">
                    <label class="field">
                      <span>Urgency</span>
                      <input name="urgency" type="range" min="1" max="5" value="${escapeAttribute(draft.urgency)}" />
                      <small>${escapeHtml(draft.urgency)} / 5</small>
                    </label>

                    <label class="field">
                      <span>People affected</span>
                      <input name="peopleAffected" type="number" min="1" value="${escapeAttribute(draft.peopleAffected)}" required />
                    </label>
                  </div>

                  <label class="field">
                    <span>Location name</span>
                    <input name="locationName" value="${escapeAttribute(draft.locationName)}" required />
                  </label>

                  <div class="inline-grid">
                    <label class="field">
                      <span>Latitude</span>
                      <input name="lat" value="${escapeAttribute(draft.lat)}" required />
                    </label>

                    <label class="field">
                      <span>Longitude</span>
                      <input name="lng" value="${escapeAttribute(draft.lng)}" required />
                    </label>
                  </div>
                </div>

                <div class="form-actions">
                  <button class="primary-button" type="submit">Save need</button>
                  <p class="panel-meta">Draft stays on this device until submitted.</p>
                </div>
              </form>
            </div>
          </section>

          <section class="page-stack ${state.view === "tasks" ? "" : "hidden"}">
            <div class="panel">
              <div class="panel-header">
                <h3>Task Board</h3>
                <span class="panel-meta">${state.tasks.length} tasks</span>
              </div>
              <div class="table-shell">
                <table>
                  <thead>
                    <tr>
                      <th>Need</th>
                      <th>Volunteer</th>
                      <th>Status</th>
                      <th>Created</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    ${state.tasks.map(renderTaskRow).join("")}
                  </tbody>
                </table>
              </div>
            </div>
          </section>

          <section class="page-stack ${state.view === "volunteers" ? "" : "hidden"}">
            <div class="panel">
              <div class="panel-header">
                <h3>Volunteer Roster</h3>
                <span class="panel-meta">Live availability snapshot</span>
              </div>
              <div class="roster-grid">
                ${state.volunteers.map(renderVolunteerCard).join("")}
              </div>
            </div>
          </section>

          <section class="page-stack ${state.view === "map" ? "" : "hidden"}">
            <div class="panel">
              <div class="panel-header">
                <div>
                  <h3>Operations Map</h3>
                  <p class="panel-subtitle">A simple free visual coverage board with no paid map dependency.</p>
                </div>
              </div>
              ${renderMap()}
            </div>
          </section>
        </main>
      </div>
    `;
  }

  function navButton(view, label) {
    return `<button class="nav-link ${state.view === view ? "active" : ""}" data-view="${view}" type="button">${label}</button>`;
  }

  function metricCard(label, value, tone) {
    return `
      <article class="metric-card ${tone}">
        <span>${label}</span>
        <strong>${value}</strong>
      </article>
    `;
  }

  function renderNeedCard(need) {
    return `
      <button class="need-card ${state.selectedNeedId === need.id ? "selected" : ""}" type="button" data-need="${need.id}">
        <div class="need-card-top">
          <strong>${escapeHtml(need.title)}</strong>
          <span class="urgency-pill urgency-${need.urgency}">${urgencyLabel(need.urgency)}</span>
        </div>
        <p>${escapeHtml(need.locationName)}</p>
        <div class="need-card-meta">
          <span>${escapeHtml(need.needType)}</span>
          <span>${need.peopleAffected} affected</span>
          <span>${formatTime(need.updatedAt)}</span>
        </div>
      </button>
    `;
  }

  function renderNeedDetail(need) {
    const candidates = state.volunteers.filter(
      (volunteer) =>
        volunteer.status === "available" &&
        volunteer.skills.some((skill) => skill.toLowerCase() === need.needType.toLowerCase())
    );

    return `
      <div class="panel-header">
        <h3>Need Detail</h3>
        <span class="urgency-pill urgency-${need.urgency}">${urgencyLabel(need.urgency)}</span>
      </div>

      <div class="detail-grid">
        <div>
          <span class="detail-label">Need</span>
          <strong>${escapeHtml(need.title)}</strong>
        </div>
        <div>
          <span class="detail-label">Status</span>
          <strong class="text-capitalize">${escapeHtml(need.status.replace("_", " "))}</strong>
        </div>
        <div>
          <span class="detail-label">Location</span>
          <strong>${escapeHtml(need.locationName)}</strong>
        </div>
        <div>
          <span class="detail-label">Reported by</span>
          <strong>${escapeHtml(need.createdBy)}</strong>
        </div>
      </div>

      <p class="detail-copy">${escapeHtml(need.description)}</p>

      <div class="detail-grid compact">
        <div>
          <span class="detail-label">People affected</span>
          <strong>${need.peopleAffected}</strong>
        </div>
        <div>
          <span class="detail-label">Updated</span>
          <strong>${formatTime(need.updatedAt)}</strong>
        </div>
      </div>

      <div class="divider"></div>

      <div class="panel-header">
        <h4>Suggested volunteers</h4>
        <span class="panel-meta">${candidates.length} available</span>
      </div>

      <div class="stack-list">
        ${
          candidates.length
            ? candidates
                .map(
                  (volunteer) => `
                    <div class="volunteer-row">
                      <div>
                        <strong>${escapeHtml(volunteer.name)}</strong>
                        <p>${escapeHtml(volunteer.skills.join(", "))}</p>
                      </div>
                      <button class="primary-button" data-assign="${need.id}:${volunteer.id}" type="button">Assign</button>
                    </div>
                  `
                )
                .join("")
            : `<p class="muted-text">No exact skill match is available right now.</p>`
        }
      </div>
    `;
  }

  function renderTaskRow(task) {
    return `
      <tr>
        <td>${escapeHtml(task.needTitle)}</td>
        <td>${escapeHtml(task.volunteerName)}</td>
        <td class="text-capitalize">${escapeHtml(task.status)}</td>
        <td>${formatTime(task.createdAt)}</td>
        <td>
          ${
            task.status !== "completed"
              ? `<button class="secondary-button" type="button" data-complete="${task.id}">Mark complete</button>`
              : `<span class="panel-meta">Done</span>`
          }
        </td>
      </tr>
    `;
  }

  function renderVolunteerCard(volunteer) {
    return `
      <article class="volunteer-card">
        <div class="need-card-top">
          <strong>${escapeHtml(volunteer.name)}</strong>
          <span class="status-badge status-${volunteer.status}">${escapeHtml(volunteer.status)}</span>
        </div>
        <p>${escapeHtml(volunteer.phone)}</p>
        <p class="muted-text">${escapeHtml(volunteer.skills.join(", "))}</p>
        <span class="panel-meta">Last active ${formatTime(volunteer.lastActiveAt)}</span>
      </article>
    `;
  }

  function renderMap() {
    const points = [
      ...state.needs.map((need) => ({ ...need, pointType: "need" })),
      ...state.volunteers.map((volunteer) => ({ ...volunteer, pointType: "volunteer" }))
    ];

    const latValues = points.map((point) => point.lat);
    const lngValues = points.map((point) => point.lng);
    const minLat = Math.min.apply(null, latValues);
    const maxLat = Math.max.apply(null, latValues);
    const minLng = Math.min.apply(null, lngValues);
    const maxLng = Math.max.apply(null, lngValues);

    const plotted = points
      .map((point) => {
        const x = normalize(point.lng, minLng, maxLng);
        const y = normalize(point.lat, minLat, maxLat);
        const top = 100 - y;
        return `
          <div class="map-dot ${point.pointType}" style="left:${x}%;top:${top}%"></div>
          <div class="map-label" style="left:${x}%;top:${top}%">${escapeHtml(point.title || point.name)}</div>
        `;
      })
      .join("");

    return `
      <div class="map-shell">
        <div class="map-board">${plotted}</div>
        <aside class="map-legend">
          <strong>Legend</strong>
          <div class="legend-item"><span class="legend-swatch" style="background:#dc2626"></span> Needs</div>
          <div class="legend-item"><span class="legend-swatch" style="background:#1d4ed8"></span> Volunteers</div>
          <p class="muted-text">This uses stored latitude and longitude to place markers in a free visual grid. It avoids map billing while keeping geographic relationships visible.</p>
        </aside>
      </div>
    `;
  }

  function normalize(value, min, max) {
    if (max === min) {
      return 50;
    }
    return 10 + ((value - min) / (max - min)) * 80;
  }

  function onClick(event) {
    const target = event.target;
    if (!(target instanceof HTMLElement)) {
      return;
    }

    if (target.dataset.view) {
      state.view = target.dataset.view;
      saveState();
      render();
      return;
    }

    if (target.dataset.need) {
      state.selectedNeedId = target.dataset.need;
      saveState();
      render();
      return;
    }

    if (target.dataset.assign) {
      const [needId, volunteerId] = target.dataset.assign.split(":");
      assignNeed(needId, volunteerId);
      return;
    }

    if (target.dataset.complete) {
      completeTask(target.dataset.complete);
      return;
    }

    if (target.dataset.action === "logout") {
      state.session = null;
      saveState();
      render();
      return;
    }

    if (target.dataset.action === "reset-draft") {
      window.localStorage.removeItem(DRAFT_KEY);
      render();
    }
  }

  function onInput(event) {
    const target = event.target;
    if (!(target instanceof HTMLElement)) {
      return;
    }

    const captureForm = root.querySelector('[data-form="capture"]');
    if (!(captureForm instanceof HTMLFormElement) || !captureForm.contains(target)) {
      return;
    }

    const formData = new FormData(captureForm);
    saveDraft(Object.fromEntries(formData.entries()));

    if (target.getAttribute("name") === "urgency") {
      render();
    }
  }

  function onSubmit(event) {
    event.preventDefault();
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) {
      return;
    }

    if (form.dataset.form === "login") {
      const data = Object.fromEntries(new FormData(form).entries());
      state.session = {
        displayName: String(data.displayName || "").trim(),
        email: String(data.email || "").trim(),
        role: String(data.role || "coordinator")
      };
      saveState();
      render();
      return;
    }

    if (form.dataset.form === "capture") {
      const data = Object.fromEntries(new FormData(form).entries());
      const title = String(data.title || "").trim();
      const description = String(data.description || "").trim();
      const locationName = String(data.locationName || "").trim();
      const lat = Number(data.lat || 0);
      const lng = Number(data.lng || 0);

      if (title.length < 5 || description.length < 10 || locationName.length < 3) {
        window.alert("Please complete the title, description, and location fields before saving.");
        return;
      }

      if (!isValidLatitude(lat) || !isValidLongitude(lng)) {
        window.alert("Please enter a valid latitude and longitude.");
        return;
      }

      const timestamp = new Date().toISOString();
      const need = {
        id: `need-${Date.now()}`,
        organizationId: "guardians",
        title,
        description,
        needType: String(data.needType || "Water"),
        urgency: Number(data.urgency || 3),
        peopleAffected: Number(data.peopleAffected || 1),
        locationName,
        lat,
        lng,
        status: "open",
        createdAt: timestamp,
        updatedAt: timestamp,
        createdBy: state.session.displayName
      };

      state.needs.unshift(need);
      state.selectedNeedId = need.id;
      state.view = "dashboard";
      window.localStorage.removeItem(DRAFT_KEY);
      saveState();
      render();
    }
  }

  function assignNeed(needId, volunteerId) {
    const need = state.needs.find((item) => item.id === needId);
    const volunteer = state.volunteers.find((item) => item.id === volunteerId);
    if (!need || !volunteer) {
      return;
    }

    need.status = "assigned";
    need.assignedVolunteerId = volunteerId;
    need.updatedAt = new Date().toISOString();
    volunteer.status = "busy";
    state.tasks.unshift({
      id: `task-${Date.now()}`,
      needId,
      volunteerId,
      needTitle: need.title,
      volunteerName: volunteer.name,
      status: "offered",
      createdAt: new Date().toISOString()
    });
    saveState();
    render();
  }

  function completeTask(taskId) {
    const task = state.tasks.find((item) => item.id === taskId);
    if (!task) {
      return;
    }

    task.status = "completed";
    const volunteer = state.volunteers.find((item) => item.id === task.volunteerId);
    const need = state.needs.find((item) => item.id === task.needId);
    if (volunteer) {
      volunteer.status = "available";
    }
    if (need) {
      need.status = "resolved";
      need.updatedAt = new Date().toISOString();
    }

    saveState();
    render();
  }

  function urgencyLabel(value) {
    if (value >= 5) {
      return "Critical";
    }
    if (value === 4) {
      return "High";
    }
    if (value === 3) {
      return "Moderate";
    }
    return "Routine";
  }

  function formatTime(value) {
    return new Intl.DateTimeFormat("en-IN", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function escapeAttribute(value) {
    return escapeHtml(value).replaceAll("`", "&#96;");
  }

  function isValidLatitude(value) {
    return Number.isFinite(value) && value >= -90 && value <= 90;
  }

  function isValidLongitude(value) {
    return Number.isFinite(value) && value >= -180 && value <= 180;
  }
})();
