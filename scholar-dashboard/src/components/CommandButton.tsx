import type { ButtonHTMLAttributes, ReactNode } from 'react'

interface CommandButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'quiet' | 'danger'
  children: ReactNode
}

export function CommandButton({
  variant = 'secondary',
  className = '',
  children,
  ...props
}: CommandButtonProps) {
  return (
    <button className={`command-button command-button--${variant} ${className}`} type="button" {...props}>
      {children}
    </button>
  )
}
