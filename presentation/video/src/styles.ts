import type {CSSProperties} from 'react';

export const colors = {
  background: '#080b10',
  panel: '#121821',
  blue: '#0866c6',
  cyan: '#42a5ff',
  white: '#f5f8ff',
  muted: '#a9b7ca',
  green: '#21c16b',
};

export const full: CSSProperties = {
  backgroundColor: colors.background,
  color: colors.white,
  fontFamily: 'Microsoft YaHei, Microsoft YaHei UI, sans-serif',
};

export const label: CSSProperties = {
  color: colors.cyan,
  fontSize: 34,
  fontWeight: 700,
  letterSpacing: 4,
};

export const title: CSSProperties = {
  fontSize: 82,
  fontWeight: 800,
  lineHeight: 1.12,
  margin: '24px 0',
};

export const subtitle: CSSProperties = {
  color: colors.muted,
  fontSize: 38,
  lineHeight: 1.55,
};
