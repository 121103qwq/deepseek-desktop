import {AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig, interpolate, Easing} from 'remotion';
import {FadeIn, Pill} from '../components';
import {colors, full, subtitle, title} from '../styles';

export const OpeningScene = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{...full, padding: '120px 140px', justifyContent: 'center'}}>
      <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(circle at 78% 28%, #0866c644, transparent 43%)'}} />
      <Img
        src={staticFile('deepseek-black-logo.png')}
        style={{
          position: 'absolute',
          right: 160,
          top: 180,
          width: 430,
          filter: 'invert(1)',
          opacity: 0.88,
          scale: interpolate(frame, [0, 1.2 * fps], [0.82, 1], {extrapolateRight: 'clamp', easing: Easing.spring({damping: 180})}),
        }}
      />
      <div style={{position: 'relative', width: 1120}}>
        <FadeIn><Pill green>Windows x64 社区发行</Pill></FadeIn>
        <FadeIn delay={12}><h1 style={{...title, fontSize: 104}}>DeepSeek Desktop</h1></FadeIn>
        <FadeIn delay={24}><div style={subtitle}>把 DeepSeek Harness 装进正常的 Windows 桌面应用</div></FadeIn>
        <FadeIn delay={38}><div style={{color: colors.cyan, fontSize: 34, marginTop: 38}}>内置 WebView · 中文默认 · Kilo 免登录路线</div></FadeIn>
      </div>
    </AbsoluteFill>
  );
};
