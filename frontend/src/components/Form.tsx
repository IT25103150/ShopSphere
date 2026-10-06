import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from 'react'

interface FieldProps {
  label: string
  error?: string
  hint?: string
  required?: boolean
  className?: string
}

function Field({ label, error, hint, required, className, id, children }: FieldProps & { id: string; children: ReactNode }) {
  return (
    <div className={`field ${className ?? ''}`}>
      <label htmlFor={id}>{label}{required && <span className="req"> *</span>}</label>
      {children}
      {hint && !error && <span className="hint">{hint}</span>}
      {error && <span className="field-error" id={`${id}-err`}>{error}</span>}
    </div>
  )
}

const fieldId = (label: string, name?: string) => name ?? label.toLowerCase().replace(/[^a-z0-9]+/g, '-')

export function FormInput({ label, error, hint, required, className, ...rest }: FieldProps & InputHTMLAttributes<HTMLInputElement>) {
  const id = fieldId(label, rest.name)
  return (
    <Field label={label} error={error} hint={hint} required={required} className={className} id={id}>
      <input id={id} className={`input ${error ? 'invalid' : ''}`} aria-invalid={!!error} aria-describedby={error ? `${id}-err` : undefined} {...rest} />
    </Field>
  )
}

export function FormSelect({ label, error, hint, required, className, children, ...rest }: FieldProps & SelectHTMLAttributes<HTMLSelectElement>) {
  const id = fieldId(label, rest.name)
  return (
    <Field label={label} error={error} hint={hint} required={required} className={className} id={id}>
      <select id={id} className={`input ${error ? 'invalid' : ''}`} aria-invalid={!!error} {...rest}>{children}</select>
    </Field>
  )
}

export function FormTextarea({ label, error, hint, required, className, ...rest }: FieldProps & TextareaHTMLAttributes<HTMLTextAreaElement>) {
  const id = fieldId(label, rest.name)
  return (
    <Field label={label} error={error} hint={hint} required={required} className={className} id={id}>
      <textarea id={id} className={`input ${error ? 'invalid' : ''}`} aria-invalid={!!error} {...rest} />
    </Field>
  )
}
