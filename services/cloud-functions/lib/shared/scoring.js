export function computePriorityScore(need, unmetHours) {
    const urgency = normalize(need.urgency_input, 1, 5);
    const unmet = clamp(unmetHours / 24, 0, 1);
    const peopleAffected = clamp(need.people_affected / 50, 0, 1);
    const reviewPenalty = need.review_required ? 0.05 : 0;
    return roundScore(urgency * 0.45 + unmet * 0.25 + peopleAffected * 0.2 - reviewPenalty + 0.1);
}
export function rankVolunteerMatches(need, volunteers) {
    return volunteers
        .filter((volunteer) => volunteer.availability_status !== "offline")
        .map((volunteer) => {
        const skillFit = volunteer.skills.some((skill) => skill.toLowerCase() === need.need_type.toLowerCase())
            ? 1
            : 0.35;
        const distanceKm = haversineKm(need.location.lat, need.location.lng, volunteer.home_location.lat, volunteer.home_location.lng);
        const proximity = clamp(1 - distanceKm / Math.max(volunteer.service_radius_km, 1), 0, 1);
        const availability = volunteer.availability_status === "available" ? 1 : 0.35;
        const acceptanceHistory = clamp(volunteer.acceptance_rate, 0, 1);
        return {
            volunteer_id: volunteer.id,
            skill_fit: skillFit,
            proximity,
            availability,
            acceptance_history: acceptanceHistory,
            score: roundScore(skillFit * 0.4 +
                proximity * 0.3 +
                availability * 0.2 +
                acceptanceHistory * 0.1),
        };
    })
        .sort((left, right) => right.score - left.score)
        .slice(0, 3);
}
function haversineKm(lat1, lon1, lat2, lon2) {
    const radians = Math.PI / 180;
    const dLat = (lat2 - lat1) * radians;
    const dLon = (lon2 - lon1) * radians;
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(lat1 * radians) *
            Math.cos(lat2 * radians) *
            Math.sin(dLon / 2) ** 2;
    return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
function normalize(value, min, max) {
    return clamp((value - min) / (max - min), 0, 1);
}
function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
}
function roundScore(value) {
    return Math.round(value * 1000) / 1000;
}
