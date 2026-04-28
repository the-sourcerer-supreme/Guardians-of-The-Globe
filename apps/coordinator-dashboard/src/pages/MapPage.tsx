import L from "leaflet";
import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import { useAppState } from "../state/AppStateContext";

const markerIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41]
});

export function MapPage() {
  const { needs, volunteers } = useAppState();

  return (
    <div className="page-stack">
      <section className="panel map-panel">
        <div className="panel-header">
          <div>
            <h3>Operations Map</h3>
            <p className="panel-subtitle">OpenStreetMap keeps this build free-tier friendly.</p>
          </div>
          <span className="panel-meta">Needs + volunteers</span>
        </div>

        <MapContainer center={[19.076, 72.8777]} zoom={12} className="map-canvas">
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {needs.map((need) => (
            <Marker key={need.id} icon={markerIcon} position={[need.lat, need.lng]}>
              <Popup>
                <strong>{need.title}</strong>
                <div>{need.locationName}</div>
              </Popup>
            </Marker>
          ))}

          {volunteers.map((volunteer) => (
            <Marker key={volunteer.id} icon={markerIcon} position={[volunteer.lat, volunteer.lng]}>
              <Popup>
                <strong>{volunteer.name}</strong>
                <div>{volunteer.skills.join(", ")}</div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </section>
    </div>
  );
}
