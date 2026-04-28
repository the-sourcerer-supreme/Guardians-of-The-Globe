export function formatTime(value: string) {
  return new Intl.DateTimeFormat("en-IN", {
    dateStyle: "medium",
    timeStyle: "short"
  }).format(new Date(value));
}

export function relativeUrgencyLabel(urgency: number) {
  if (urgency >= 5) {
    return "Critical";
  }
  if (urgency === 4) {
    return "High";
  }
  if (urgency === 3) {
    return "Moderate";
  }
  return "Routine";
}
