import type {ReactNode} from 'react';
import {Easing, Img, interpolate, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {colors} from './styles';

export const FadeIn = ({children, delay = 0}: {children: ReactNode; delay?: number}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <div
      style={{
        opacity: interpolate(frame, [delay, delay + 0.7 * fps], [0, 1], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
          easing: Easing.bezier(0.16, 1, 0.3, 1),
        }),
        translate: interpolate(frame, [delay, delay + 0.7 * fps], ['0px 28px', '0px 0px'], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
          easing: Easing.bezier(0.16, 1, 0.3, 1),
        }),
      }}
    >
      {children}
    </div>
  );
};

export const Screenshot = ({src, width, height}: {src: string; width: number; height?: number}) => (
  <div style={{borderRadius: 28, overflow: 'hidden', boxShadow: '0 32px 100px #000a', border: '1px solid #ffffff22'}}>
    <Img src={staticFile(src)} style={{display: 'block', width, height, objectFit: 'cover'}} />
  </div>
);

export const Pill = ({children, green = false}: {children: ReactNode; green?: boolean}) => (
  <div
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: 14,
      padding: '15px 24px',
      borderRadius: 999,
      background: green ? '#113b2a' : '#0c2c4e',
      color: green ? '#66efaa' : '#7fc5ff',
      fontSize: 28,
      fontWeight: 700,
      border: `1px solid ${green ? '#21c16b55' : colors.cyan + '55'}`,
    }}
  >
    {green ? '●' : '◆'} {children}
  </div>
);
