'use client';

import type { CSSProperties, FormHTMLAttributes, HTMLAttributes, LabelHTMLAttributes } from 'react';
import React from 'react';

const cardStyle: CSSProperties = {
  backgroundColor: '#ffffff',
  borderRadius: '12px',
  border: '1px solid #e5e7eb',
  padding: '20px',
  boxShadow: '0 8px 24px rgba(15, 23, 42, 0.08)',
  marginBottom: '24px',
};

const sectionTitleStyle: CSSProperties = {
  fontSize: '1.25rem',
  fontWeight: 600,
  marginBottom: '12px',
  color: '#0f172a',
};

const descriptionStyle: CSSProperties = {
  fontSize: '0.95rem',
  color: '#475569',
  marginBottom: '18px',
  lineHeight: 1.5,
};

const buttonStyle: CSSProperties = {
  background: 'linear-gradient(135deg, #2563eb 0%, #7c3aed 100%)',
  border: 'none',
  color: '#ffffff',
  fontWeight: 600,
  padding: '10px 18px',
  borderRadius: '8px',
  cursor: 'pointer',
  boxShadow: '0 12px 30px rgba(37, 99, 235, 0.25)',
  transition: 'transform 0.15s ease, box-shadow 0.15s ease',
};

const secondaryButtonStyle: CSSProperties = {
  ...buttonStyle,
  background: '#e2e8f0',
  color: '#1e293b',
  boxShadow: 'none',
};

const inputStyle: CSSProperties = {
  width: '100%',
  padding: '10px 12px',
  borderRadius: '8px',
  border: '1px solid #cbd5f5',
  fontSize: '0.95rem',
  marginBottom: '12px',
  boxSizing: 'border-box',
};

const labelStyle: CSSProperties = {
  fontSize: '0.85rem',
  fontWeight: 600,
  color: '#1e293b',
  display: 'block',
  marginBottom: '6px',
};

const badgeStyle: CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  gap: '6px',
  fontSize: '0.8rem',
  fontWeight: 600,
  backgroundColor: '#f1f5f9',
  color: '#1e293b',
  padding: '6px 10px',
  borderRadius: '999px',
};

const logPanelStyle: CSSProperties = {
  backgroundColor: '#0f172a',
  color: '#e2e8f0',
  fontFamily: 'Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
  fontSize: '0.8rem',
  padding: '16px',
  borderRadius: '10px',
  maxHeight: '220px',
  overflowY: 'auto',
  whiteSpace: 'pre-wrap',
};

export function PageContainer({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #f8fafc 0%, #edf2ff 100%)',
        padding: '32px 0',
      }}
    >
      <div style={{ maxWidth: '960px', margin: '0 auto', padding: '0 24px' }}>{children}</div>
    </div>
  );
}

export function SectionCard({ children, style }: { children: React.ReactNode; style?: CSSProperties }) {
  return <section style={{ ...cardStyle, ...style }}>{children}</section>;
}

export function SectionTitle({ children }: { children: React.ReactNode }) {
  return <h2 style={sectionTitleStyle}>{children}</h2>;
}

export function SectionDescription({ children }: { children: React.ReactNode }) {
  return <p style={descriptionStyle}>{children}</p>;
}

export function Button(
  props: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' }
) {
  const { variant = 'primary', style, ...rest } = props;
  const baseStyle = variant === 'primary' ? buttonStyle : secondaryButtonStyle;

  return (
    <button
      {...rest}
      style={{
        ...baseStyle,
        ...(rest.disabled
          ? { opacity: 0.6, cursor: 'not-allowed', boxShadow: 'none', transform: 'none' }
          : {}),
        ...style,
      }}
      onMouseDown={(event) => {
        if (!rest.disabled) {
          event.currentTarget.style.transform = 'scale(0.98)';
        }
      }}
      onMouseUp={(event) => {
        if (!rest.disabled) {
          event.currentTarget.style.transform = 'scale(1)';
        }
      }}
    />
  );
}

export function TextInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  const { style, ...rest } = props;
  return <input {...rest} style={{ ...inputStyle, ...style }} />;
}

export function Label(props: LabelHTMLAttributes<HTMLLabelElement>) {
  const { style, children, ...rest } = props;
  return (
    <label {...rest} style={{ ...labelStyle, ...style }}>
      {children}
    </label>
  );
}

export function Badge({ children }: { children: React.ReactNode }) {
  return <span style={badgeStyle}>{children}</span>;
}

export function LogPanel({ children }: { children: React.ReactNode }) {
  return <div style={logPanelStyle}>{children}</div>;
}

export function InlineCode({ children }: { children: React.ReactNode }) {
  return (
    <code
      style={{
        backgroundColor: '#e2e8f0',
        color: '#0f172a',
        padding: '2px 6px',
        borderRadius: '6px',
        fontSize: '0.85rem',
        fontFamily: 'Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
      }}
    >
      {children}
    </code>
  );
}

export function Fieldset({ children, legend }: { children: React.ReactNode; legend?: string }) {
  return (
    <fieldset
      style={{
        border: '1px dashed #cbd5f5',
        borderRadius: '10px',
        padding: '16px',
        marginBottom: '16px',
      }}
    >
      {legend ? (
        <legend
          style={{
            fontSize: '0.85rem',
            fontWeight: 600,
            padding: '0 6px',
            color: '#475569',
          }}
        >
          {legend}
        </legend>
      ) : null}
      {children}
    </fieldset>
  );
}

export function Form(props: FormHTMLAttributes<HTMLFormElement>) {
  const { style, ...rest } = props;
  return (
    <form
      {...rest}
      style={{
        display: 'grid',
        gap: '12px',
        ...style,
      }}
    />
  );
}

export function PillList({ items }: { items: Array<{ label: string; value: string | number }> }) {
  if (!items.length) {
    return null;
  }
  return (
    <div
      style={{
        display: 'flex',
        flexWrap: 'wrap',
        gap: '8px',
        marginTop: '12px',
      }}
    >
      {items.map((item) => (
        <span
          key={`${item.label}-${item.value}`}
          style={{
            backgroundColor: '#dbeafe',
            color: '#1d4ed8',
            borderRadius: '999px',
            padding: '6px 10px',
            fontSize: '0.8rem',
            fontWeight: 600,
          }}
        >
          {item.label}: {item.value}
        </span>
      ))}
    </div>
  );
}

export function OutputPanel({ title, data }: { title: string; data: unknown }) {
  return (
    <div style={{ marginTop: '12px' }}>
      <Label style={{ marginBottom: '6px' }}>{title}</Label>
      <LogPanel>{JSON.stringify(data, null, 2)}</LogPanel>
    </div>
  );
}
