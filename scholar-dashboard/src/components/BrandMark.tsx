export function BrandMark({ size = 36 }: { size?: number }) {
  return (
    <svg
      aria-hidden="true"
      className="brand-mark"
      fill="none"
      height={size}
      viewBox="0 0 42 42"
      width={size}
    >
      <path d="M5 8.5c5 .7 9.2 2.7 12.3 6.2v19C13.8 30.9 9.7 29.3 5 29V8.5Z" />
      <path d="M37 8.5c-5 .7-9.2 2.7-12.3 6.2v19c3.5-2.8 7.6-4.4 12.3-4.7V8.5Z" />
      <path d="M17.3 14.7c1.6 1.4 2.8 3 3.7 4.9.9-1.9 2.1-3.5 3.7-4.9M21 19.6V36" />
      <path d="M5 29c6 .5 11.3 2.8 16 7 4.7-4.2 10-6.5 16-7" />
    </svg>
  )
}
