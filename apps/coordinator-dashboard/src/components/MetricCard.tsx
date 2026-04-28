interface MetricCardProps {
  label: string;
  value: string;
  tone?: "neutral" | "critical" | "good";
}

export function MetricCard({ label, value, tone = "neutral" }: MetricCardProps) {
  return (
    <article className={`metric-card metric-${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}
